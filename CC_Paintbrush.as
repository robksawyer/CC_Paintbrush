package {
	import flash.display.MovieClip;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.text.TextFieldAutoSize;

	import flash.utils.Timer;
    import flash.events.TimerEvent;
	import flash.events.Event;

	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;


	//Logging
	import com.demonsters.debugger.MonsterDebugger;

	//import the Resolume communication classes
	//make sure you have added the source path to these files in the ActionScript 3 Preferences of Flash
	import resolumeCom.*;
	import resolumeCom.parameters.*;
	import resolumeCom.events.*;

	public class CC_Paintbrush extends MovieClip 
	{
	
		/*****************TEST PARAMS********************/
		
		private static var TESTING:Boolean = false;
		
		/************************************************/
		
		
		/*****************PRIVATE********************/
		/**
		* Create the resolume object that will do all the hard work for you.
		*/
		private var resolume:Resolume = new Resolume();
		
		/**
		* Examples of parameters that can be used inside of Resolume
		*/
		/*private var paramScaleX:FloatParameter = resolume.addFloatParameter("Scale X", 0.5);
		private var paramScaleY:FloatParameter = resolume.addFloatParameter("Scale Y", 0.5);
		private var paramRotate:FloatParameter = resolume.addFloatParameter("Rotate", 0.0);
		private var paramFooter:StringParameter = resolume.addStringParameter("Footer", "VJ BOB");
		private var paramShowBackground:BooleanParameter = resolume.addBooleanParameter("Background", true);
		private var paramShowSurprise:EventParameter = resolume.addEventParameter("Surprise!");*/
		
		
		//Other Resolume Parameters
		private var paramBrush:EventParameter;
		private var paramPencil:EventParameter;
		private var paramEraser:EventParameter;
		private var paramClear:EventParameter;
		private var paramHideApp:EventParameter;

		private var paramLine:BooleanParameter;
		private var paramCurve:BooleanParameter;

		private var paramDraw:FloatParameter;
		private var paramDrawDelay:FloatParameter;
		//private var paramDrawRepeat:FloatParameter;
		//
		private var paramCursorXPos:FloatParameter;
		private var paramCursorYPos:FloatParameter;
		private var paramBrushXPos:FloatParameter;
		private var paramBrushYPos:FloatParameter;
		//
		private var paramBrushSize:FloatParameter;
		private var paramBrushColor:FloatParameter;

		private var totalBrushes = 12;
		private var totalPencils = 3;
		private var totalColors = 28;
		private var appHidden = false;

		private var prevX1Pos:Number = 0;
		private var prevY1Pos:Number = 0;
		private var x1Pos:Number = 0;
		private var y1Pos:Number = 0;
		private var prevX2Pos:Number = 0;
		private var prevY2Pos:Number = 0;
		private var x2Pos:Number = 0;
		private var y2Pos:Number = 0;

		/* Handles the speed at which things are drawn to the canvas. */
		private var drawDelay:uint;
		//private var drawRepeat:uint;
		private var drawTimer:Timer;
		
		/* Pencil Tool shape, everything drawn with this tool and the eraser tool is stored inside board.pencilDraw */
		private var pencilDraw:Shape = new Shape();
		 
		/* Text format */
		private var textformat:TextFormat = new TextFormat();
		 
		/* Colors */
		private var colorsBmd:BitmapData; //We'll use this Bitmap Data to get the pixel RGB Value when clicked
		private var pixelValue:uint;
		private var activeColor:uint = 0x000000; //This is the current color in use, displayed by the shapeSize MC
		private var colors:Array = new Array(
		  0x000000, 0x808080, 0x820000, 0x7F8100, 0x008100, 0x008082, 0x000082, 0x820081, 0x80813B, 0x004040, 0x007CFF, 0x003E82, 0x8000FF, 0x814000,
		  0xFFFFFF, 0xD6D6D6, 0xFF0000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF, 0xFF00FF, 0xFFFF78, 0x00FF7B, 0x7BFFFF, 0x807CFF, 0xFF007F, 0xFF8036
		);
		 
		/* Active var, to check which tool is active */
		private var active:String;

		private var drawing:Boolean = false; //Handles state
		 
		/* Shape size color */
		private var ct:ColorTransform = new ColorTransform();

		private var clickCounter:int = 0;
		private var brushSize:uint = 0;
		private var curBrush:MovieClip;
		private var curPencil:MovieClip;

		/*****************PUBLIC********************/

		public var BG:MovieClip;
		public var CANVAS:MovieClip;
		public var SWATCH:MovieClip;
		public var BRUSH:MovieClip;
		public var PENCIL:MovieClip;
		public var ERASER:MovieClip;
		public var BRUSHES:MovieClip;
		public var PENCILS:MovieClip;


		public function CC_Paintbrush():void
		{

			textformat.font = "Quicksand Bold Regular"; // You can use any font you like
			textformat.bold = true;
			textformat.size = 16;

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			// Start the MonsterDebugger
			MonsterDebugger.initialize(this);
			MonsterDebugger.clear();

			BG = this["bg"];
			CANVAS = this["canvas"];
			SWATCH = this["colorSwatch"];
			BRUSH = this["brush"];
			PENCIL = this["pencil"];
			ERASER = this["eraser"];
			BRUSHES = this["brushes"];
			PENCILS = this["pencils"];

			BRUSHES.visible = false;
			PENCILS.visible = false;

			//Initialize the Resolume parameters
			initParams();

			addListeners();
		}

		/**
		*
		* Adds the listeners
		*
		**/
		private function addListeners():void
		{
			//set callback, this will notify us when a parameter has changed
			resolume.addParameterListener(paramChanged);
		
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		/**
		*
		* Handles changing the color of the brush/pencil
		* @param paramVal:Number The index that points to a color in the color array
		* @return void
		**/
		private function chooseColor(paramVal:Number = 0):uint
		{
			var nColor:int = int(paramVal * totalColors);
			/* Use a ColorTransform object to change the shapeSize MovieClip color */
			ct.color = colors[nColor];
			pencilDraw = new Shape();
			CANVAS.addChild(pencilDraw);

			//curBrush.transform.colorTransform = ct;
			//curPencil.transform.colorTransform = ct;
			pencilDraw.transform.colorTransform = ct;
			SWATCH.transform.colorTransform = ct;

			return ct.color;
		}
		
		
		/**
		*
		* Initialize parameters that are used inside of Resolume
		*
		**/
		public function initParams():void
		{
		  MonsterDebugger.trace(this, "Iniailizing Resolume parameters.", "Init Phase");
		  
		  //Floats
		  paramBrush = resolume.addEventParameter("Start Brush");
		  paramPencil = resolume.addEventParameter("Start Pencil");
		  paramEraser = resolume.addEventParameter("Start Eraser");
		  paramClear = resolume.addEventParameter("Clear");
		  paramHideApp = resolume.addEventParameter("Toggle App");

		  paramLine = resolume.addBooleanParameter("Make Lines", false);
		  paramCurve = resolume.addBooleanParameter("Make Curves", false);

		  paramDraw = resolume.addFloatParameter("Draw", 0.6 );
		  paramDrawDelay = resolume.addFloatParameter("Draw Speed", 0.2 );
		  //paramDrawRepeat = resolume.addFloatParameter("Draw Repeat", 0 ); //0 = infinite 
		  //
		  paramCursorXPos = resolume.addFloatParameter("Cursor X Pos", 0.0 );
		  paramCursorYPos = resolume.addFloatParameter("Cursor Y Pos", 0.0 );
		  paramBrushXPos = resolume.addFloatParameter("Brush X Pos", 0.0 );
		  paramBrushYPos = resolume.addFloatParameter("Brush Y Pos", 0.0 );
		  //
		  paramBrushSize = resolume.addFloatParameter("Brush Size", 0.14 );
		  paramBrushColor = resolume.addFloatParameter("Brush Color", 0.0 );
		}
	  
		/**
		*
		* Main initialize method
		*
		**/
		public function init( e:Event ):void
		{
			MonsterDebugger.trace(this, "Initialized", "Init Phase");

			if(TESTING)
			{
				PencilTool();
			}
		}

		/**
		*
		* Main Pencil tool method
		*
		**/
		private function BrushTool():void
		{
			/* Quit active tool */

			quitActiveTool(); //This function will be created later

			/* Set to Active */
			active = "Brush"; //Sets the active variable to "Pencil"
			BRUSHES.visible = true;

			if(!curBrush)
			{
				curBrush = BRUSHES.brush1;
			}

			pencilDraw = new Shape(); //We add a new shape to draw always in top (in case of text, or eraser drawings)
			CANVAS.addChild(pencilDraw); //Add that shape to the CANVAS MovieClip

			/* Adds the listeners to the board MovieClip, to draw just in it */
			if(TESTING)
			{
				drawDelay = paramDrawDelay.getValue() * 10000;
				//drawRepeat = int(paramDrawRepeat.getValue() * 10);
			}


			/* Highlight, sets the Pencil Tool Icon to the color version, and hides any other tool */
			highlightTool(BRUSH);
			hideTools(ERASER, PENCIL);

			/* Sets the active color variable based on the Color Transform value and uses that color for the shapeSize MovieClip */
			chooseColor(paramBrushColor.getValue());
			changeBrushSize();

			//Start the drawing
			if(drawTimer && drawTimer.running)
			{
				drawTimer.stop();
			}
			drawTimer = new Timer(drawDelay, 0);
			drawTimer.addEventListener("timer", startBrushTool);
			drawTimer.start();
		}

		/**
		*
		* Starts the drawing
		*
		**/
		private function startBrushTool(e:TimerEvent):void
		{
			if(TESTING)
			{
				x1Pos = randomRange(0, CANVAS.width - CANVAS.x);
				y1Pos = randomRange(0, CANVAS.height - CANVAS.y);
				x2Pos = randomRange(0, CANVAS.width - CANVAS.x);
				y2Pos = randomRange(0, CANVAS.height - CANVAS.y);
			}
			MonsterDebugger.trace(this, "x1: " + x1Pos + " y1: " + y1Pos + " x2: " + x2Pos + " y2: " + y2Pos);
			if(prevX1Pos != x1Pos || prevY1Pos != y1Pos){
				pencilDraw.graphics.moveTo(x1Pos, y1Pos); //Moves the Drawing Position to the Mouse Position
				prevX1Pos = x1Pos;
				prevY1Pos = y1Pos;
			}
			pencilDraw.graphics.lineStyle(brushSize, activeColor);//Sets the line thickness to the ShapeSize MovieClip size and sets its color to the current active color
		 
			if(paramDraw.getValue() >= 0.5)
			{
				drawBrushTool(); //Adds a listener to the next function
			}
			else
			{
			  stopBrushTool();
			}
		}

		/**
		*
		* Start the actual drawing
		*
		**/
		
		private function drawBrushTool():void
		{
			drawing = true;
			if(prevX2Pos != x2Pos || prevY2Pos != y2Pos){
				if(paramLine.getValue() == true)
				{
					pencilDraw.graphics.lineTo(x2Pos, y2Pos); //Draws a line from the current Mouse position to the moved Mouse position
				}
				else if(paramCurve.getValue() == true)
				{
					pencilDraw.graphics.curveTo(x1Pos, y1Pos, x2Pos, y2Pos); //Draws a line from the current Mouse position to the moved Mouse position
				}
				else
				{
					pencilDraw.graphics.lineTo(x1Pos+1, y1Pos+1); //Draws a line from the current Mouse position to the moved Mouse position
				}
				
				prevX2Pos = x2Pos;
				prevY2Pos = y2Pos;
			}
		}

		/**
		*
		* Stop the drawing
		*
		**/
		private function stopBrushTool():void
		{
			drawing = false;
			drawTimer.stop();
			drawTimer.removeEventListener("timer", startBrushTool);
		}

		/**
		*
		* Main Pencil tool method
		*
		**/
		private function PencilTool():void
		{
			/* Quit active tool */

			quitActiveTool(); //This function will be created later

			/* Set to Active */
			active = "Pencil"; //Sets the active variable to "Pencil"
			PENCILS.visible = true;

			if(!curPencil)
			{
				curPencil = PENCILS.pencil1;
			}

			pencilDraw = new Shape(); //We add a new shape to draw always in top (in case of text, or eraser drawings)
			CANVAS.addChild(pencilDraw); //Add that shape to the CANVAS MovieClip

			/* Adds the listeners to the board MovieClip, to draw just in it */
			if(TESTING)
			{
				drawDelay = paramDrawDelay.getValue() * 10000;
				//drawRepeat = paramDrawRepeat.getValue() * 10;
			}
			

			/* Highlight, sets the Pencil Tool Icon to the color version, and hides any other tool */
			highlightTool(PENCIL);
			hideTools(ERASER, BRUSH);

			/* Sets the active color variable based on the Color Transform value and uses that color for the shapeSize MovieClip */
			chooseColor(paramBrushColor.getValue());
			changeBrushSize();

			//Start the draw timer
			if(drawTimer && drawTimer.running)
			{
				drawTimer.stop();
			}
			drawTimer = new Timer(drawDelay, 0);
			drawTimer.addEventListener("timer", startPencilTool);
			drawTimer.start();
		}

		/**
		*
		* Starts the drawing
		*
		**/
		private function startPencilTool(e:TimerEvent):void
		{
			if(TESTING)
			{
				x1Pos = randomRange(0, CANVAS.width - CANVAS.x);
				y1Pos = randomRange(0, CANVAS.height - CANVAS.y);
				x2Pos = randomRange(0, CANVAS.width - CANVAS.x);
				y2Pos = randomRange(0, CANVAS.height - CANVAS.y);
			}
			MonsterDebugger.trace(this, "x1: " + x1Pos + " y1: " + y1Pos + " x2: " + x2Pos + " y2: " + y2Pos);
			if(prevX1Pos != x1Pos || prevY1Pos != y1Pos){
				pencilDraw.graphics.moveTo(x1Pos, y1Pos); //Moves the Drawing Position to the Mouse Position
				prevX1Pos = x1Pos;
				prevY1Pos = y1Pos;
			}
			pencilDraw.graphics.lineStyle(brushSize, activeColor);//Sets the line thickness to the ShapeSize MovieClip size and sets its color to the current active color
		 
			if(paramDraw.getValue() >= 0.5)
			{
				drawPencilTool(); //Adds a listener to the next function
			}
			else
			{
			  stopPencilTool();
			}
		}

		/**
		*
		* Start the actual drawing
		*
		**/
		
		private function drawPencilTool():void
		{
			drawing = true;
			if(prevX2Pos != x2Pos || prevY2Pos != y2Pos){
			
				if(paramLine.getValue() == true)
				{
					pencilDraw.graphics.lineTo(x2Pos, y2Pos); //Draws a line from the current Mouse position to the moved Mouse position
				}
				else if(paramCurve.getValue() == true)
				{
					pencilDraw.graphics.curveTo(x1Pos, y1Pos, x2Pos, y2Pos); //Draws a line from the current Mouse position to the moved Mouse position
				}
				else
				{
					pencilDraw.graphics.lineTo(x1Pos+1, y1Pos+1); //Draws a line from the current Mouse position to the moved Mouse position
				}

				prevX2Pos = x2Pos;
				prevY2Pos = y2Pos;
			}
		}

		/**
		*
		* Stop the drawing
		*
		**/
		private function stopPencilTool():void
		{
			drawing = false;
			drawTimer.stop();
			drawTimer.removeEventListener("timer", startPencilTool);
		}
		

		/**
		*
		* The Eraser tool
		*
		**/
		private function EraserTool():void
		{
			/* Quit active tool */
		
			quitActiveTool();
		
			/* Set to Active */
		
			active = "Eraser";
			
			pencilDraw = new Shape();
			CANVAS.addChild(pencilDraw);

			/* Listeners */
			//CANVAS.addEventListener(Event.ENTER_FRAME, startEraserTool);
			if(TESTING)
			{
				drawDelay = paramDrawDelay.getValue() * 10000;
				//drawRepeat = paramDrawRepeat.getValue() * 10;
			}

			/* Highlight */
			highlightTool(ERASER);
			hideTools(PENCIL, BRUSH);
		
			/* Use White Color */
			ct.color = 0xFFFFFF;
			pencilDraw.transform.colorTransform = ct;

			//Start the draw timer
			if(drawTimer && drawTimer.running)
			{
				drawTimer.stop();
			}
			drawTimer = new Timer(drawDelay, 0);
			drawTimer.addEventListener("timer", startEraserTool);
			drawTimer.start();
		}
		
		/**
		*
		* Start the erasing
		*
		**/
		private function startEraserTool(e:Event):void
		{
			MonsterDebugger.trace(this, "x1: " + x1Pos + " y1: " + y1Pos + " x2: " + x2Pos + " y2: " + y2Pos);
			if(prevX1Pos != x1Pos || prevY1Pos != y1Pos){
				pencilDraw.graphics.moveTo(x1Pos, y1Pos); //Moves the Drawing Position to the Mouse Position
				prevX1Pos = x1Pos;
				prevY1Pos = y1Pos;
			}
			pencilDraw.graphics.lineStyle(BRUSHES.brush1.width, 0xFFFFFF);//Sets the line thickness to the ShapeSize MovieClip size and sets its color to the current active color
		 
			if(paramDraw.getValue() >= 0.5)
			{
				drawEraserTool(); //Adds a listener to the next function
			}
			else
			{
			  stopEraserTool();
			}
		}
		

		private function drawEraserTool():void
		{
			drawing = true;
			if(prevX2Pos != x2Pos || prevY2Pos != y2Pos){
			
				if(paramLine.getValue() == true)
				{
					pencilDraw.graphics.lineTo(x2Pos, y2Pos); //Draws a line from the current Mouse position to the moved Mouse position
				} 
				else if(paramCurve.getValue() == true)
				{
					pencilDraw.graphics.curveTo(x1Pos, y1Pos, x2Pos, y2Pos); //Draws a line from the current Mouse position to the moved Mouse position
				}
				else
				{
					pencilDraw.graphics.lineTo(x1Pos+1, y1Pos+1); //Draws a line from the current Mouse position to the moved Mouse position
				}
				prevX2Pos = x2Pos;
				prevY2Pos = y2Pos;
			}
		}
		 
		private function stopEraserTool():void
		{
			drawing = false;
			drawTimer.stop();
			drawTimer.removeEventListener("timer", startEraserTool);
		}

		/**
		*
		* Clear the canvas
		*
		**/
		private function clearBoard():void
		{
			/* Create a white rectangle on top of everything */
			var blank:Shape = new Shape();
		 
			blank.graphics.beginFill(0xFFFFFF);
			blank.graphics.drawRect(0, 0, CANVAS.width, CANVAS.height);
			blank.graphics.endFill();
		 
			CANVAS.addChild(blank);
		}

		/**
		*
		* Handles switching tools 
		*
		**/
		private function quitActiveTool():void
		{
			switch (active)
			{
				case "Pencil":
					stopPencilTool();
					PENCILS.visible = false;
					CANVAS.removeEventListener(Event.ENTER_FRAME, startPencilTool);
					break;

				case "Brush":
					stopBrushTool();
					BRUSHES.visible = false;
					CANVAS.removeEventListener(Event.ENTER_FRAME, startBrushTool);
					break;

				case "Eraser":
					stopEraserTool();
					CANVAS.removeEventListener(Event.ENTER_FRAME, startEraserTool);
					break;

				case "Clear":
					clearBoard();
					break;
		
				default:
					break;
			}
		}

		private function highlightTool(tool:MovieClip):void
		{
			tool.gotoAndStop(2); //Highlights tool in the parameter
		}

		/* Hides the tools in the parameters */

		private function hideTools(tool1:MovieClip, tool2:MovieClip):void
		{
			tool1.gotoAndStop(1);
			tool2.gotoAndStop(1);
		}

		/**
		*
		* Handles changing the brush size
		*
		**/
		private function changeBrushSize():void
		{
			var maxVal = 1;
			if(active == "Brush")
			{
				var nBrush:int = int(paramBrushSize.getValue() * totalBrushes);
				MonsterDebugger.trace(this, "New brush: " + nBrush, "Brush");
				updateToolSize(BRUSHES["brush" + nBrush]);
				
			}
			else if(active == "Pencil")
			{
				var nPencil:int = int(paramBrushSize.getValue() * totalPencils);
				MonsterDebugger.trace(this, "New pencil: " + nPencil, "Pencil");
				updateToolSize(PENCILS["pencil" + nPencil]);
			}
		}

		private function updateToolSize(tool:MovieClip):void
		{
			//Remove the highlight from other brushes
			if(active == "Brush")
			{
				for(var i=1;i<=totalBrushes;i++)
				{
					BRUSHES["brush" + i].gotoAndStop(1);
				}
				curBrush = tool;
			}
			else if(active == "Pencil")
			{
				for(var j=1;j<=totalPencils;j++)
				{
					PENCILS["pencil" + j].gotoAndStop(1);
				}
				curPencil = tool;
			}

			//Update the brush size
			brushSize = tool.width;

			//Highlight the current tool
			tool.gotoAndStop(2);
		}

		/**
		*
		* Hides the MS Paint interface and only shows the painting
		*
		**/
		private function toggleAppInterface():void
		{
			if(appHidden)
			{
				PENCILS.visible = true;
				BRUSHES.visible = true;
				PENCIL.visible = true;
				ERASER.visible = true;
				BRUSH.visible = true;
				SWATCH.visible = true;
				BG.visible = true;
				appHidden = false;
			}
			else
			{
				PENCILS.visible = false;
				BRUSHES.visible = false;
				PENCIL.visible = false;
				ERASER.visible = false;
				BRUSH.visible = false;
				SWATCH.visible = false;
				BG.visible = false;
				appHidden = true;
			}
			
		}
		

		/**
		* This method will be called everytime you change a paramater in Resolume.
		*/
		public function paramChanged( event:ChangeEvent ):void 
		{
			//MonsterDebugger.trace(this, "Param Changed: " + event.object, "Interactive Phase");
			switch(event.object)
			{

				case paramBrush:
					if(clickCounter < 1)
					{
						clickCounter++;
					}
					else
					{
						MonsterDebugger.trace(this,"Brush selected!", "Tool");
						BrushTool();
						clickCounter = 0;
					}
					break;

				case paramPencil:
					if(clickCounter < 1)
					{
						clickCounter++;
					}
					else
					{
						MonsterDebugger.trace(this,"Pencil selected!", "Tool");
						PencilTool();
						clickCounter = 0;
					}
					break;

				case paramEraser:
					if(clickCounter < 1)
					{
						clickCounter++;
					}
					else
					{
						MonsterDebugger.trace(this,"Eraser selected!", "Tool");
						EraserTool();
						clickCounter = 0;
					}
					break;

				case paramClear:
					if(clickCounter < 1)
					{
						clickCounter++;
					}
					else
					{
						MonsterDebugger.trace(this,"Board cleared!", "Tool");
						clearBoard();
						clickCounter = 0;
					}
					break;

				case paramHideApp:
					if(clickCounter < 1)
					{
						clickCounter++;
					}
					else
					{
						MonsterDebugger.trace(this,"Toggling the app interface!", "Tool");
						toggleAppInterface();
						clickCounter = 0;
					}
					break;

				case paramDrawDelay:
					drawDelay = paramDrawDelay.getValue() * 100; //Convert to milliseconds
					drawTimer = new Timer(drawDelay, 0);
					drawTimer.start();
					break;

				/*case paramDrawRepeat:
					drawRepeat = paramDrawDelay.getValue() * 10;
					drawTimer = new Timer(drawDelay, 0);
					drawTimer.start();
					break;*/

				case paramCursorXPos:
					//Move the brush via the x-axis 
					x1Pos = paramCursorXPos.getValue() * (CANVAS.width - CANVAS.x);
					break;

				case paramCursorYPos:
					//Move the brush via the y-axis 
					y1Pos = paramCursorYPos.getValue() * (CANVAS.height - CANVAS.y);
					break;

				case paramBrushXPos:
					//Paints via the x-axis 
					x2Pos = paramBrushXPos.getValue() * (CANVAS.width - CANVAS.x);
					break;

				case paramBrushYPos:
					//Paints via the y-axis 
					y2Pos = paramBrushYPos.getValue() * (CANVAS.height - CANVAS.y);
					break;

				case paramBrushSize:
					//Select a brush size
					changeBrushSize();
					break;

				case paramBrushColor:
					//Select a color 
					if(active != "Eraser")
					{
						var nColor = chooseColor(paramBrushColor.getValue());
						MonsterDebugger.trace(this, "Index:  " + nColor + " / New Color: " + colors[nColor], "Color");
					}
					break;

				default:
					MonsterDebugger.trace(this, event.object);
					break;
			}
		}

		/**
		*
		* Generates a random number within a set range
		* @param minNum:Number
		* @param maxNum:Number
		* @return Number
		* 
		**/
		private function randomRange(minNum:Number, maxNum:Number):Number 
		{
			return (Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum);
		}

	}
}