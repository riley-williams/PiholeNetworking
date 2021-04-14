//
//  MockJSON+Experimental.swift
//  PiholeNetworking
//
//  Created by Riley Williams on 4/13/21.
//

import Foundation

extension MockJSON {
	static let network = """
	{"network":[{"id":1,"hwaddr":"e2:63:da:cf:06:49","interface":"eth0","firstSeen":1595281320,"lastQuery":1598333042,"numQueries":37,"macVendor":"","aliasclient_id":null,"ip":[],"name":[]},{"id":2,"hwaddr":"ac:22:0b:dc:36:07","interface":"eth0","firstSeen":1595281320,"lastQuery":1611724979,"numQueries":43414,"macVendor":"ASUSTek COMPUTER INC.","aliasclient_id":null,"ip":["192.168.2.67"],"name":[""]},{"id":3,"hwaddr":"64:16:66:a5:39:7e","interface":"eth0","firstSeen":1595281320,"lastQuery":1618362001,"numQueries":50317,"macVendor":"Nest Labs Inc.","aliasclient_id":null,"ip":["192.168.4.130"],"name":["09AA01AF25190K44.UDM"]},{"id":4,"hwaddr":"c0:97:27:3b:3c:c0","interface":"eth0","firstSeen":1595291040,"lastQuery":1618362297,"numQueries":732398,"macVendor":"Samsung Electro-Mechanics(Thailand)","aliasclient_id":null,"ip":["192.168.1.158","192.168.1.157","192.168.1.156","192.168.1.160","192.168.1.159"],"name":["localhost.UDM","localhost.UDM","localhost.UDM","",""]},{"id":5,"hwaddr":"ip-192.168.2.213","interface":"N/A","firstSeen":1595771760,"lastQuery":1611911057,"numQueries":2911,"macVendor":"","aliasclient_id":null,"ip":["192.168.2.213"],"name":[""]}]}
	"""
}
