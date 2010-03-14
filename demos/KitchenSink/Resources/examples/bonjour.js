// Publish a local service on startup
var bonjourSocket = Titanium.Socket.createTCP({
	hostName:Titanium.Socket.INADDR_ANY,
	port:40401,
	mode:Titanium.Socket.READ_WRITE_MODE
});

bonjourSocket.addEventListener('read', function(e) {
	var remoteSocket = e['from'];
	var dataStr = e['data'].text;
	if (dataStr == 'req') {
		bonjourSocket.write('Hello, from '+Titanium.Platform.id, remoteSocket);
	}
	else {
		Titanium.UI.createAlertDialog({
			title:'Unknown listener message...',
			message:dataStr
		}).show();
		// WARNING: There's some weird issue here where data events may or may
		// not interact with UI update events (including logging) and this
		// may result in some very ugly undefined behavior... that hasn't been
		// detected before because only UI elements have fired events in the
		// past.
		// Unfortunately, Bonjour is completely asynchronous and requires event
		// firing: Sockets require it as well to reliably deliver information
		// about when new data is available.
		// In particular if UI elements are updated 'out of order' with socket
		// data (especially modal elements, like dialogs, from inside the callback)
		// there may be some very bad results.  Like... crashes.
	}
});
bonjourSocket.listen();

var localService = Titanium.Bonjour.createService({
	service:{name:'Bonjour Test: '+Titanium.Platform.id,
			type:'_utest._tcp',
			domain:'local.',
			socket:bonjourSocket}
});

try {
	localService.publish();
}
catch (e) {
	Titanium.UI.createAlertDialog({
		title:'Error!',
		message:e
	}).show();
}

// Searcher for finding other services
var serviceBrowser = Titanium.Bonjour.createBrowser({
	serviceType:'_utest._tcp',
	domain:'local.'
});

var tableView = Titanium.UI.createTableView({
	style:Titanium.UI.iPhone.TableViewStyle.GROUPED,
	data:[{title:'No services', hasChild:false}]
});

tableView.addEventListener('click', function(r) {
	var service = r['rowData'].service;
	service.socket.write('req');
});

var services = null;
updateUI = function(e) {
	var data = [];
	services = e['services'];
	
	for (var i=0; i < services.length; i++) {
		var service = services[i];
		var row = Titanium.UI.createTableViewRow({
			title:service.name,
			service:service
		});
		
		service.resolve();
		service.socket.addEventListener('read', function(x) {
			Titanium.UI.createAlertDialog({
				title:'Bonjour message!',
				message:x['data'].text
			}).show();
		});
		service.socket.connect();
		
		data.push(row);
	}
	
	if (data.length == 0) {
		data.push(Titanium.UI.createTableViewRow({
			title:'No services'
		}));
	}
	
	tableView.setData(data);
}

serviceBrowser.addEventListener('updatedServices', updateUI);

// Cleanup
Titanium.UI.currentWindow.addEventListener('blur', function(e) {
	if (serviceBrowser.isSearching()) {
		serviceBrowser.stopSearch();
	}
	Titanium.API.info('Stopped search...');
	localService.stop();
	Titanium.API.info('Stopped service...');
	if (bonjourSocket.isValid()) {
		bonjourSocket.close();
	}
	Titanium.API.info('Closed socket...');
	for (var i=0; i < services.length; i++) {
		var service = services[i];
		if (service.socket.isValid()) {
			service.socket.close();
		}
		Titanium.API.info('Closed socket to service '+service.name+"...");
	}
});

serviceBrowser.search();
Titanium.UI.currentWindow.add(tableView);