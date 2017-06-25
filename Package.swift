
import PackageDescription

let package = Package(
	name: "TortoiseAPId",
	targets: [
		
	],
	dependencies: [
		.Package(url:"https://github.com/PerfectlySoft/PerfectLib.git", majorVersion: 2, minor: 0),
		.Package(url:"https://github.com/PerfectlySoft/Perfect-HTTP.git", majorVersion: 2, minor: 0),
		.Package(url:"https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2, minor: 0),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Curl.git", majorVersion: 2, minor: 0),
		.Package(url:"https://github.com/PerfectlySoft/Perfect-MySQL.git", majorVersion: 2, minor: 0),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Crypto.git", majorVersion: 1)
	]
)
