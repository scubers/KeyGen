
import Foundation

struct RandomDataGen {
    let count: Int
    let metas = "0123456789~!@#$%^&*()?>,./=-_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    private(set) var randomString: String = ""
    init(_ count: Int) {
        self.count = count
        randomString = generate()
    }
    private func generate() -> String {
        let meta = Array(metas)
        print(meta.count)
        var result = [String]()
        for i in 0..<count {
            let target = i % meta.count
            var index = 0
            if result.count > 2 {
                index = Int.random(in: 0..<result.count)
            }
            result.insert(String(meta[target]), at: index)
        }
        return result.joined()
    }
    
    
    func randomIndex(of char: String) -> Int {
        let times = max(1, randomString.count / metas.count - 2)
        let indexCount = Int.random(in: 0..<times)
        var flag = 0
        var stringIndex = -1
        let targetIndex = randomString.firstIndex(where: { c -> Bool in
            stringIndex += 1
            let target = String(c)
            if target != char {
                return false
            }
            guard flag == indexCount else {
                flag += 1
                return false
            }
            return true
        })
        assert(targetIndex != nil)
        return stringIndex
    }
    
    func getIndexArray(_ input: String) -> [Int] {
        var result = [Int]()
        input.forEach { (c) in
            let index = randomIndex(of: String(c))
            result.append(index)
        }
        return result
    }
}

struct Keys: Codable {
    var name: String
    var keys: [String: String]
}

/// typeof --arg1=xx --arg2=yy
fileprivate class CommandLineArgsFetcher {
    var origins = [String]()
    init(args: [String]) {
        self.origins = args
    }
    func get(_ key: String) -> String? {
        for arg in origins {
            let fix = "--\(key)="
            if arg.hasPrefix(fix) {
                return arg.replacingOccurrences(of: fix, with: "")
            }
        }
        return nil
    }
    func conatain(_ key: String) -> Bool {
        for arg in origins {
            let fix = "--\(key)"
            if arg.hasPrefix(fix) {
                return true
            }
        }
        return false
    }
}


fileprivate let params = CommandLineArgsFetcher(args: CommandLine.arguments)

if params.conatain("help") {
    print("""
输入参数：
    --input=/xx/yy/zz: 需要扫描的key路径
    --output=/xx/yy/zz: 导出文件
    --name=/xx/yy/zz: 关键字
    --length=1000: 混淆码长度
""")
    exit(0)
}

guard let name = params.get("name") else {
    print("请输入name")
    exit(-1)
}

guard let input = params.get("input") else {
    print("请输入input")
    exit(-1)
}

guard let output = params.get("output") else {
    print("请输入output")
    exit(-1)
}

let length = Int(params.get("length") ?? "1000") ?? 1000

let gen = RandomDataGen(length)

let keys = try! JSONDecoder().decode([Keys].self, from: FileManager.default.contents(atPath: input)!)
let dict = keys.filter({ $0.name == name }).first!.keys

let dataString = gen.randomString.map({ "\"\($0)\"" }).joined(separator: ",")
var code = "import KeyGen\n"
code += "fileprivate let metaDatas = [\(dataString)]\n"
code += "@objc public extension KeyStore {\n"
code += "    @objc public static func get(_ key: String) -> String? {\n"
code += "        switch key {\n"
dict.forEach { (key, value) in
    code += "        case \"\(key)\": return [\(gen.getIndexArray(value).map({ "metaDatas[\($0)]" }).joined(separator: ","))].joined()\n"
}
code += "        default: return nil\n"
code += "        }\n"
code += "    }\n"
code += "}\n"
try! code.write(to: URL(fileURLWithPath: output), atomically: true, encoding: .utf8)
