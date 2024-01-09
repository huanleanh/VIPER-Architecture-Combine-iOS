let myAPI = MyAPI()

// Load the fake response
let data = try Data(contentsOf: Bundle.main.url(forResource: "users", withExtension: "json")!)

// Create a fake response
let fakeResponse = try JSONDecoder().decode([User].self, from: data)

// Replace the real response with the fake response
myAPI.getUsers() = Just(fakeResponse)

// Use the API
myAPI.getUsers().sink { response in
  // Do something with the response
}


[
  {
    "name": "John Doe"
  },
  {
    "name": "Jane Doe"
  }
]

ham check kieu request de tao request tuong ung.

enum APIRequestType {
    case none
    case ocfRequest
    case d2dRequest
    case httpsRequest
}

func apiRequest(speaker: ISpeaker, apiInfo: IAPIInfo) {

----
attr    OBJC_RCSResourceAttributes    0x0000000281b04880
baseNSObject@0    NSObject    
_m_values    __NSDictionaryM *    1 key/value pair    0x0000000281ded9c0
[0]    (null)    "volume" : 0x0000000280153d40    
key    NSTaggedPointerString?    "volume"    0x8a4283e9d012494e
value    OBJC_RCSResourceAttributesValue?    0x0000000280153d40
self    SPKController.VLOcfResourceAudio    0x0000000280b929d0
SPKController.VLOcfResource    SPKController.VLOcfResource    
uri    String    "/sec/networkaudio/audio"    
speaker    SPKController.VLSpeaker?    0x0000000120ab3a00
ocfDevice    OBJC_OCFDevice    0x0000000281f7a4e0
baseNSObject@0    NSObject    
isa    Class    OBJC_OCFDevice    0x3b00000120331041


