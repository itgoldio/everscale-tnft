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
    code_data = ts4.load_code_cell('Data.tvc')

    nft_root = ts4.BaseContract('NftRoot', ctor_params = {'codeIndex': code_index, 'codeData': code_data, 'ownerPubkey': keypair[1]}, keypair = keypair)
    return nft_root

#Nft root methods
def mint(setcodemultisig, nft_root):
    payload = ts4.encode_message_body('NftRoot', 'mintNft', {})
    setcodemultisig.call_method_signed('sendTransaction', {'dest': nft_root.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_messages()
    addr_data = nft_root.call_getter('resolveData', {'addrRoot': nft_root.address, 'id': 0})
    ts4.Address.ensure_address(addr_data)
    data = ts4.BaseContract('Data', ctor_params = None, address = addr_data)
    
    return data

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


# Data methods 
def get_info(data):
    return data.call_getter('getInfo')

def get_owner(data):
    return data.call_getter('getOwner')

def transfer_ownership(data, owner, new_owner):
    payload = ts4.encode_message_body('Data', 'transferOwnership', {'addrTo': new_owner.address})
    owner.call_method_signed('sendTransaction', {'dest': data.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
    ts4.dispatch_messages()

def get_index_deploy_value(data):
    return data.call_getter('getIndexDeployValue')

def set_index_deploy_value(data, owner, value):
    payload = ts4.encode_message_body('Data', 'setIndexDeployValue', {'indexDeployValue': value})
    owner.call_method_signed('sendTransaction', {'dest': data.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
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

#mint
data = mint(setcodemultisig, nft_root)

#get_info test
answer = get_info(data)
exp_answer = (nft_root.address, setcodemultisig.address, data.address)
assert eq(exp_answer, answer)

#transfer_ownership test
answer = get_owner(data)
exp_answer = setcodemultisig.address
assert eq(exp_answer, answer)

transfer_ownership(data, setcodemultisig, setcodemultisig2)

answer = get_owner(data)
exp_answer = setcodemultisig2.address
assert eq(exp_answer, answer)

#get_index_deploy_value test
answer = get_index_deploy_value(data)
assert eq(400000000, answer)

#set_index_deploy_value
set_index_deploy_value(data, setcodemultisig2, 900000000)
answer = get_index_deploy_value(data)
assert eq(900000000, answer)