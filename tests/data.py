import tonos_ts4.ts4 as ts4

eq = ts4.eq

ts4.init('../src/compiled', verbose = True)
VENDORING_PATH='../../tests/vendoring/'

def deploy_setcodemultisig():
    keypair = ts4.make_keypair()
    setcodemultisig = ts4.BaseContract(VENDORING_PATH + 'setcodemultisig/SetcodeMultisigWallet', ctor_params = {'owners': [keypair[1]], 'reqConfirms': 1}, keypair = keypair)
    return setcodemultisig

def deposit(setcodemultisig, dest, value):
    setcodemultisig.call_method_signed('sendTransaction', {'dest': dest, 'value': value, 'bounce': False, 'flags': 0, 'payload': ts4.Cell("")})
    ts4.dispatch_messages()

def deploy_nft_root(setcodemultisig):
    keypair = setcodemultisig.keypair
    code_nft = ts4.load_code_cell('Nft.tvc')

    nft_root = ts4.BaseContract('NftRoot', ctor_params = {'codeNft': code_nft, 'ownerPubkey': keypair[1]}, keypair = keypair)
    return nft_root

#Nft root methods
def mint(setcodemultisig, nft_root, name, json):
    json = ts4.str2bytes(json)
    payload = ts4.encode_message_body('NftRoot', 'mintNft', {"dataName": ts4.str2bytes(name), "json": json})
    setcodemultisig.call_method_signed('sendTransaction', {'dest': nft_root.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_messages()
    addr_nft = nft_root.call_getter('resolveNft', {'addrRoot': nft_root.address, 'id': 0})
    ts4.Address.ensure_address(addr_nft)
    nft = ts4.BaseContract('Nft', ctor_params = None, address = addr_nft)
    event = ts4.pop_event()
    
    return nft

def checkInterface(nft, selector):
    return nft.call_getter('supportsInterface', {"_answer_id": 0, "interfaceID": selector})

def support_interfaces_test(nft):
    name_selector = 1118824496
    nft_base_selector = 154153079
    tip6_selector = 839183401

    print("selectors:")
    print(name_selector)
    print(nft_base_selector)
    print(tip6_selector)

    assert (True, checkInterface(nft, name_selector))
    assert (True, checkInterface(nft, nft_base_selector))
    assert (True, checkInterface(nft, tip6_selector))
    assert (False, checkInterface(nft, 000000))

def transfer_ownership_test(old_owner, new_owner, nft):
    payload = ts4.encode_message_body('Nft', 'transferOwnership', {"sendGasToAddr": ts4.zero_addr(0), "addrTo": new_owner.address, "callbacks": {}})
    
    # try to call transfer with invalid owner (sender)
    new_owner.call_method_signed('sendTransaction', {'dest': nft.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_one_message(expect_ec = 104)
    ts4.dispatch_messages()

    # try to call transfer with invalid addrTo
    invalid_payload = ts4.encode_message_body('Nft', 'transferOwnership', {"sendGasToAddr": ts4.zero_addr(0), "addrTo": ts4.zero_addr(0), "callbacks": {}})
    old_owner.call_method_signed('sendTransaction', {'dest': nft.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': invalid_payload}, expect_ec = 0)
    ts4.dispatch_one_message(expect_ec = 101)
    ts4.dispatch_messages()

    old_owner.call_method_signed('sendTransaction', {'dest': nft.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_messages()
    event = ts4.pop_event()
    assert event.is_event('OwnershipTransferred', src = nft.address, dst = ts4.Address(None))
    assert eq(event.params['newOwner'], new_owner.address.str() )
    assert eq(event.params['oldOwner'], old_owner.address.str())
    (id, addrOwner, addrCollection, addrManager) = nft.call_getter('getInfo', {"_answer_id": 0})
    assert eq(new_owner.address, addrOwner)

def name_test(nft, name):
    assert eq(name, nft.call_getter('getName', {"_answer_id": 0}))


setcodemultisig = deploy_setcodemultisig()
setcodemultisig2 = deploy_setcodemultisig()

nft_root = deploy_nft_root(setcodemultisig)
name = "Test"
json = "{}"
nft = mint(setcodemultisig, nft_root, name, json)

support_interfaces_test(nft)

deposit(setcodemultisig, nft.address, 5000000000)

transfer_ownership_test(setcodemultisig, setcodemultisig2, nft)

name_test(nft, name)
