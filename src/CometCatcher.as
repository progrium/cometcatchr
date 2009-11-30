package {
	import com.adobe.net.URI;
	import com.adobe.serialization.json.*;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.errors.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.system.*;
	import flash.utils.*;
	
	import org.httpclient.HttpClient;
	import org.httpclient.events.*;

	public class CometCatcher extends Sprite
	{	
		private var params:Object;
		private var client:HttpClient;
		private var log:Function;
		
		private var retry:Number = 1;
		private var maxRetries:Number = 3;
		
		public function CometCatcher()
		{
			// Load params
			params = LoaderInfo(this.root.loaderInfo).parameters;
			
			// Load values from params if specified
			if (params.policy) { Security.loadPolicyFile(params.policy); }
			if (params.retry) { maxRetries = params.retry; }
			
			// Make sure ExternalInterface is available
			if (!ExternalInterface.available) {
				trace("Error: No external interface available");
			}
			
			// Set up logger
			if (params.logger) {
				log = function(msg:String):void { ExternalInterface.call(params.logger, "CometCatcher: " + msg); };
			} else {
				log = trace;
			}
			
			// Set up HTTP client
			client = new HttpClient(null, 3600000);
			
			// Go!
			connect();
		}
		
		public function setupEventHandlers():void {
			client.listener.onData = onData;
			client.listener.onError = onError;
			client.listener.onClose = onClose;
			client.listener.onConnect = onConnect;
		}
		
		public function connect():void {
			log("Connecting to " + params.url);
			setupEventHandlers();
			client.get(new URI(params.url));
		}
		
		public function attemptReconnect():void {
			if (retry <= maxRetries) {
				log("Retry attempt " + retry.toString() + ":");
				retry += 1;
				connect();
			}
			
		}

		public function onData(event:HttpDataEvent):void {
			ExternalInterface.call(params.callback, JSON.decode(event.readUTFBytes()));
		}

		public function onConnect(event:Event):void {
			log("Connected and listening...");
			retry = 1;
		}
		
		public function onClose(event:Event):void {
			log("Connection closed.");
			client.listener = null;
			client.close();
			setTimeout(attemptReconnect, 1000*retry);
		}
		
		public function onError(event:ErrorEvent):void {
			log("HTTP Error: " + event.text);
		}
	}
}
