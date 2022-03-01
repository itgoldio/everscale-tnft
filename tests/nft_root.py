import tonos_ts4.ts4 as ts4

eq = ts4.eq

ts4.init('../src/compiled', verbose = True)
VENDORING_PATH='../../tests/vendoring/'

def deploy_setcodemultisig():
    keypair = ts4.make_keypair()
    setcodemultisig = ts4.BaseContract(VENDORING_PATH + 'setcodemultisig/SetcodeMultisigWallet', ctor_params = {'owners': [keypair[1]], 'reqConfirms': 1}, keypair = keypair)
    return setcodemultisig

def deploy_nft_root(keypair, owner_pubkey, code_nft, expect_ec):
    nft_root = ts4.BaseContract('NftRoot', ctor_params = None, keypair = keypair)
    nft_root.call_method('constructor', {'codeNft': code_nft, 'ownerPubkey': owner_pubkey}, expect_ec = expect_ec)
    return nft_root

def mint_nft(nft_root, setcodemultisig, msg_value, expect_ec):
    data_name = ts4.str2bytes("Test")
    json = ts4.str2bytes("{}")
    payload = ts4.encode_message_body('NftRoot', 'mintNft', {"dataName": data_name, "json": json})
    setcodemultisig.call_method_signed('sendTransaction', {'dest': nft_root.address, 'value': msg_value, 'bounce': False, 'flags': 0, 'payload': payload})
    ts4.dispatch_one_message(expect_ec = expect_ec)
    ts4.dispatch_messages()
    if (expect_ec == 0):
        addr_nft = nft_root.call_getter('resolveNft', {'addrRoot': nft_root.address, 'id': 0})
        ts4.Address.ensure_address(addr_nft)
        nft = ts4.BaseContract('Nft', ctor_params = None, address = addr_nft)
        return nft

    return None

def withdraw(nft_root, private_key, to, value, expect_ec):
    nft_root.call_method('withdraw', {'to': to, 'value': value}, private_key = private_key, expect_ec = expect_ec)
    ts4.dispatch_messages()


def deploy_nft_root_test():
    code_nft = ts4.load_code_cell('Nft.tvc')

    # deploy with empty code nft
    keypair = ts4.make_keypair()
    nft_root = deploy_nft_root(keypair, keypair[1], ts4.Cell(""), 105)

    # deploy with empty code index
    keypair = ts4.make_keypair()
    nft_root = deploy_nft_root(keypair, keypair[1], code_nft, 0)

    # deploy with empty owner pubkey
    keypair = ts4.make_keypair()
    nft_root = deploy_nft_root(keypair, 0x0, code_nft, 100)

    #deploy with valid values
    keypair = ts4.make_keypair()
    nft_root = deploy_nft_root(keypair, keypair[1], code_nft, 0)
    assert eq(0, nft_root.call_getter('getTotalMinted'))

def mint_nft_test(setcodemultisig):

    keypair = ts4.make_keypair()
    code_nft = ts4.load_code_cell('Nft.tvc')
    nft_root = deploy_nft_root(keypair, keypair[1], code_nft, 0)
    total_minted = nft_root.call_getter('getTotalMinted')

    # mint nft with valid msg value
    nft = mint_nft(nft_root, setcodemultisig, 1300000000, 0)
    assert eq(("Test"), nft.call_getter('getName', {"_answer_id": 0}))
    event = ts4.pop_event()
    assert event.is_event('TokenWasMinted', src = nft_root.address, dst = ts4.Address(None))
    assert eq(event.params['creatorAddr'], setcodemultisig.address.str() )
    assert eq(event.params['nftAddr'], nft.address.str())
    total_minted += 1
    assert eq(total_minted, nft_root.call_getter('getTotalMinted'))

def withdraw_test(setcodemultisig):

    keypair = ts4.make_keypair()
    code_nft = ts4.load_code_cell('Nft.tvc')
    nft_root = deploy_nft_root(keypair, keypair[1], code_nft, 0)

    to = setcodemultisig.address

    # attempt to withdraw more evers than there are on the account
    nft_root_balance = ts4.get_balance(nft_root.address)
    value = nft_root_balance + 1000000000
    withdraw(nft_root, nft_root.keypair[0], to, value, 104)

    # attempt to request output from an incorrect key
    keypair = ts4.make_keypair()
    value = 1000000000
    withdraw(nft_root, keypair[0], to, value, 101)

    multisig_balance = ts4.get_balance(setcodemultisig.address)
    value = 1000000000
    withdraw(nft_root, nft_root.keypair[0], to, value, 0)
    setcodemultisig.ensure_balance(multisig_balance + value)

def setters_test():
    keypair = ts4.make_keypair()
    code_nft = ts4.load_code_cell('Nft.tvc')
    nft_root = deploy_nft_root(keypair, keypair[1], code_nft, 0)

    set_remain_on_nft_test(nft_root)

def set_remain_on_nft_test(nft_root): 

    value = 990000000

    keypair = ts4.make_keypair()
    nft_root.call_method('setRemainOnNft', {'remainOnNft': value}, private_key = keypair[0], expect_ec = 101)
    ts4.dispatch_messages()

    nft_root.call_method('setRemainOnNft', {'remainOnNft': value}, private_key = nft_root.keypair[0], expect_ec = 0)
    ts4.dispatch_messages()
    assert eq(990000000, nft_root.call_getter('getRemainOnNft'))

setcodemultisig = deploy_setcodemultisig()

deploy_nft_root_test()
mint_nft_test(setcodemultisig)
withdraw_test(setcodemultisig)
setters_test()