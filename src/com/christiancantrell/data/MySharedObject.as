package com.christiancantrell.data
{
	import flash.desktop.NativeApplication;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class MySharedObject
	{
		public var data:Object;
		private var f:File;
		
		public function MySharedObject(key:String)
		{
			this.f = File.userDirectory.resolvePath("Library/Application Support/" + NativeApplication.nativeApplication.applicationID + "/" + key);
			if (f.exists)
			{
				var fs:FileStream = new FileStream();
				fs.open(this.f, FileMode.READ);
				this.data = fs.readObject();
				fs.close();
			}
			else
			{
				this.data = new Object();
			}
		}
				
		public static function getLocal(key:String):MySharedObject
		{
			return new MySharedObject(key);
		}
		
		public function flush():void
		{
			var fs:FileStream = new FileStream();
			fs.open(this.f, FileMode.WRITE);
			fs.writeObject(this.data);
			fs.close();
		}
	}
}