source 'https://github.com/CocoaPods/Specs.git'
source 'git@gitlab.xuanke.com:iOS/KCSpecs.git'

platform:ios,'8.0'
use_frameworks!

def init_pods
    pod 'Alamofire'#, '4.6.0'
    pod 'ObjectMapper'#, '3.1.0'
    pod 'AlamofireObjectMapper'#,'5.0.0'
    pod 'SwiftyJSON'#,'4.0.0'
    pod 'CodableAlamofire'

    pod 'CocoaLumberjack/Swift'#, '3.4.1'
    pod 'CryptoSwift','0.8.3'

    pod 'EasySQLite'  #解决编译问题
end

target 'BaseNetwork' do
    init_pods
end

target 'BaseNetworkTests' do
    init_pods
    pod 'Quick'
    pod 'Nimble'
end
