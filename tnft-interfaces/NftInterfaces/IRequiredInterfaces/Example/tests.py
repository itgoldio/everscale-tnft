import tonos_ts4.ts4 as ts4

eq = ts4.eq

ts4.init('./', verbose = True)
VENDORING_PATH='../../../vendoring/'

#deploy
keypair = ts4.make_keypair()
setcodemultisig = ts4.BaseContract(VENDORING_PATH + 'setcodemultisig/SetcodeMultisigWallet', ctor_params = {'owners': [keypair[1]], 'reqConfirms': 1}, keypair = keypair)

codeIndex = ts4.load_code_cell(VENDORING_PATH + 'compiled/Index.tvc')
codeData = ts4.load_code_cell('compiled/Data.tvc')

nftRoot = ts4.BaseContract('compiled/NftRoot', ctor_params = {'codeIndex': codeIndex, 'codeData': codeData}, keypair = keypair)

payload = ts4.encode_message_body('compiled/NftRoot', 'mintNft', {})
setcodemultisig.call_method_signed('sendTransaction', {'dest': nftRoot.address, 'value': 2000000000, 'bounce': False, 'flags': 0, 'payload': payload}, expect_ec = 0)
ts4.dispatch_messages()

#resolve data addr
addrData = nftRoot.call_getter('resolveData', {'addrRoot': nftRoot.address, 'id': 0})
ts4.Address.ensure_address(addrData)
data = ts4.BaseContract('compiled/Data', ctor_params = None, address = addrData)

#id
IRequiredInterfaces = 1
ReqInterfaces = [IRequiredInterfaces]

answReqInterfaces = data.call_getter('getRequiredInterfaces')

assert eq(answReqInterfaces, ReqInterfaces)