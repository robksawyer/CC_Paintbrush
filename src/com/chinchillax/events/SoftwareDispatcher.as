﻿package com.chinchillax.events{		import flash.events.EventDispatcher;	import flash.events.Event;		public class SoftwareDispatcher extends EventDispatcher {				public static var UPDATE_VIDEO:String = "updatevideo";			public function updateVideo():void {			dispatchEvent(new Event(SoftwareDispatcher.UPDATE_VIDEO));		}			}}