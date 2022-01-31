import tonos_ts4.ts4 as ts4

eq = ts4.eq

ts4.init('../src/compiled', verbose = True)
VENDORING_PATH='../../tests/vendoring/'

def deploy_setcodemultisig():
    keypair = ts4.make_keypair()
    setcodemultisig = ts4.BaseContract(VENDORING_PATH + 'setcodemultisig/SetcodeMultisigWallet', ctor_params = {'owners': [keypair[1]], 'reqConfirms': 1}, keypair = keypair)
    return setcodemultisig

def deploy_nft_root(setcodemultisig):
    keypair = setcodemultisig.keypair
    code_index = ts4.load_code_cell('Index.tvc')
    code_nft = ts4.load_code_cell('Nft.tvc')

    nft_root = ts4.BaseContract('NftRoot', ctor_params = {'codeIndex': code_index, 'codeNft': code_nft, 'ownerPubkey': keypair[1]}, keypair = keypair)
    return nft_root

#Nft root methods
def mint(setcodemultisig, nft_root):
    payload = ts4.encode_message_body('NftRoot', 'mintNft', {})
    setcodemultisig.call_method_signed('sendTransaction', {'dest': nft_root.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_messages()
    addr_nft = nft_root.call_getter('resolveNft', {'addrRoot': nft_root.address, 'id': 0})
    ts4.Address.ensure_address(addr_nft)
    nft = ts4.BaseContract('Nft', ctor_params = None, address = addr_nft)
    
    return nft

def resolveIndexes(nft_root, nft, setcodemultisig): 
    zero_address = ts4.Address('0:' + '0'*64)
    addr_or = nft.call_getter('resolveIndex', {'addrRoot': nft_root.address, 'addrData': nft.address, 'addrOwner': setcodemultisig.address})
    addr_o = nft.call_getter('resolveIndex', {'addrRoot': zero_address, 'addrData': nft.address, 'addrOwner': setcodemultisig.address})

    ts4.Address.ensure_address(addr_or)
    index_1 = ts4.BaseContract('Index', ctor_params = None, address = addr_or)
    ts4.Address.ensure_address(addr_o)
    index_2 = ts4.BaseContract('Index', ctor_params = None, address = addr_o)

    return index_1, index_2

def verify_indexes(nft_root, nft, setcodemultisig): 
    (index_1, index_2) = resolveIndexes(nft_root, nft, setcodemultisig)
    answer = index_1.call_getter('getInfo')
    exp_answer = (nft_root.address, setcodemultisig.address, nft.address)
    assert eq(exp_answer, answer)
    answer = index_2.call_getter('getInfo')
    exp_answer = (nft_root.address, setcodemultisig.address, nft.address)
    assert eq(exp_answer, answer)

def getIndexBasisAddress(nft_root):
    return nft_root.call_getter('getIndexBasisAddress')

def deployIndexBasis(nft_root, code_index_basis):
    nft_root.call_method_signed('deployIndexBasis', {'codeIndexBasis': code_index_basis})
    ts4.dispatch_messages()
    addr_index_basis = getIndexBasisAddress(nft_root)
    ts4.Address.ensure_address(addr_index_basis)
    index_basis = ts4.BaseContract('IndexBasis', ctor_params = None, address = addr_index_basis)

    return index_basis

def destructIndexBasis(nft_root):
    nft_root.call_method_signed('destructIndexBasis', {})
    ts4.dispatch_messages()

def withdraw(nft_root, to, value):
    nft_root.call_method_signed('withdraw', {'to': to, 'value': value})
    ts4.dispatch_messages()


# Nft methods 
def get_info(nft):
    return nft.call_getter('getInfo')

def get_owner(nft):
    return nft.call_getter('getOwner', {'_answer_id': 0})

def transfer_ownership(nft, owner, new_owner):
    payload = ts4.encode_message_body('Nft', 'transferOwnership', {'addrTo': new_owner.address})
    owner.call_method_signed('sendTransaction', {'dest': nft.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_messages()

def get_index_deploy_value(nft):
    return nft.call_getter('getIndexDeployValue', {'_answer_id': 0})

def set_index_deploy_value(nft, owner, value):
    payload = ts4.encode_message_body('Nft', 'setIndexDeployValue', {'indexDeployValue': value})
    owner.call_method_signed('sendTransaction', {'dest': nft.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_messages()



setcodemultisig = deploy_setcodemultisig()
setcodemultisig2 = deploy_setcodemultisig()
nft_root = deploy_nft_root(setcodemultisig)

#withdraw test
balance = nft_root.balance
value = 1000000000
exp_answer = balance - value
withdraw(nft_root, setcodemultisig.address, value)
assert eq(exp_answer, nft_root.balance)

#deployIndexBasis test
# index_basis = deployIndexBasis(nft_root, ts4.load_code_cell('IndexBasis.tvc'))

#mint nft test
nft = mint(setcodemultisig, nft_root)
# check that indexes was deployed
verify_indexes(nft_root, nft, setcodemultisig)

#get_info test
answer = get_info(nft)
exp_answer = (nft_root.address, setcodemultisig.address, nft.address)
assert eq(exp_answer, answer)

# #transfer_ownership test
answer = get_owner(nft)
exp_answer = setcodemultisig.address
assert eq(exp_answer, answer)

# from ITransfer
transfer_ownership(nft, setcodemultisig, setcodemultisig2)

answer = get_owner(nft)
exp_answer = setcodemultisig2.address
assert eq(exp_answer, answer)

# check that indexes was redeployed after transfer ownership
verify_indexes(nft_root, nft, setcodemultisig2)

#get_index_deploy_value test
answer = get_index_deploy_value(nft)
assert eq(400000000, answer)

# #set_index_deploy_value
set_index_deploy_value(nft, setcodemultisig2, 900000000)
answer = get_index_deploy_value(nft)
assert eq(900000000, answer)
