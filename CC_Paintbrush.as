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
		private var paramDraw:FloatParameter;
		private var paramAccel:FloatParameter;
		private var paramXPos:FloatParameter;
		private var paramYPos:FloatParameter;
		private var paramBrushSize:FloatParameter;
		private var paramBrushColor:FloatParameter;

		private var xPos:Number = 0;
		private var yPos:Number = 0;
		
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


		/*****************PUBLIC********************/

		public var CANVAS:MovieClip;
		public var PENCIL:MovieClip;
		public var ERASER:MovieClip;
		public var BRUSHES:MovieClip;


		public function CC_Paintbrush():void
		{

			textformat.font = "Quicksand Bold Regular"; // You can use any font you like
			textformat.bold = true;
			textformat.size = 16;

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			// Start the MonsterDebugger
			MonsterDebugger.initialize(this);

			CANVAS = this["canvas"];
			PENCIL = this["pencil"];
			ERASER = this["eraser"];
			BRUSHES = this["brushes"];

			//Initialize the Resolume parameters
			initParams();

			//convertToBMD();

			addListeners();

			/* Hide tools highlights */

			pencil.visible = false;
			//hideTools(eraser, txt);

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
		* Cover the color to bitmap
		*
		**/
		private function convertToBMD():void
		{
			//colorsBmd = new BitmapData(colors.width,colors.height);
			//colorsBmd.draw(colors);
		}
		
		/**
		*
		* Handles changing the color of the brush/pencil
		* @param index:int The index that points to a color in the color array
		* @return void
		**/
		private function chooseColor(index:int = 0):void
		{
			//pixelValue = colorsBmd.getPixel(colors.mouseX,colors.mouseY); //Gets RGB value
			//activeColor = pixelValue;
		
			/* Use a ColorTransform object to change the shapeSize MovieClip color */
			ct.color = colors[index];
			//shapeSize.transform.colorTransform = ct;
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
		  paramDraw = resolume.addFloatParameter("Draw", 0.0 );
		  paramAccel = resolume.addFloatParameter("Acceleration", 0.2 );
		  paramXPos = resolume.addFloatParameter("Brush X Pos", 0.0 );
		  paramYPos = resolume.addFloatParameter("Brush Y Pos", 0.0 );
		  paramBrushSize = resolume.addFloatParameter("Brush Size", 0.5 );
		  paramBrushColor = resolume.addFloatParameter("Brush Color", 0.1 );
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
		  
		  }
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

			/* Adds the listeners to the board MovieClip, to draw just in it */

			//CANVAS.addEventListener(MouseEvent.MOUSE_DOWN, startPencilTool);
			//CANVAS.addEventListener(MouseEvent.MOUSE_UP, stopPencilTool);

			/* Highlight, sets the Pencil Tool Icon to the color version, and hides any other tool */

			//highlightTool(pencil);
			//hideTools(eraser, txt);

			/* Sets the active color variable based on the Color Transform value and uses that color for the shapeSize MovieClip */

			ct.color = colors[0];
			//shapeSize.transform.colorTransform = ct;
		}

		/**
		*
		* Starts the drawing
		*
		**/
		private function startPencilTool():void
		{
			pencilDraw = new Shape(); //We add a new shape to draw always in top (in case of text, or eraser drawings)
			CANVAS.addChild(pencilDraw); //Add that shape to the CANVAS MovieClip
		 
			pencilDraw.graphics.moveTo(xPos, yPos); //Moves the Drawing Position to the Mouse Position
			pencilDraw.graphics.lineStyle(BRUSHES.brush1.width, activeColor);//Sets the line thickness to the ShapeSize MovieClip size and sets its color to the current active color
		 
			if(paramDraw.getValue() >= 0.5)
			{
				if(!drawing){
					CANVAS.addEventListener(Event.ENTER_FRAME, drawPencilTool); //Adds a listener to the next function
				}
			}
			else
			{
			  stopPencilTool();
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
			CANVAS.removeEventListener(Event.ENTER_FRAME, drawPencilTool); //Stops the drawing
		}

		/**
		*
		* Start the actual drawing
		*
		**/
		
		private function drawPencilTool(e:Event):void
		{
			drawing = true;
			pencilDraw.graphics.lineTo(xPos, yPos); //Draws a line from the current Mouse position to the moved Mouse position
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
		
			/* Listeners */
		
			//CANVAS.addEventListener(MouseEvent.MOUSE_DOWN, startEraserTool);
			//CANVAS.addEventListener(MouseEvent.MOUSE_UP, stopEraserTool);
		
			/* Highlight */
			//highlightTool(eraser);
			//hideTools(pencil, txt);
		
			/* Use White Color */
			ct.color = 0xFFFFFF;
			//shapeSize.transform.colorTransform = ct;
		}
		
		/**
		*
		* Start the erasing
		*
		**/
		private function startEraserTool():void
		{
			pencilDraw = new Shape();
			CANVAS.addChild(pencilDraw);
		 
			pencilDraw.graphics.moveTo(xPos, yPos);
			pencilDraw.graphics.lineStyle(BRUSHES.brush1.width, 0xFFFFFF); //White Color
		 
			CANVAS.addEventListener(Event.ENTER_FRAME, drawEraserTool);
		}
		

		private function drawEraserTool(e:Event):void
		{
			pencilDraw.graphics.lineTo(xPos, yPos);
		}
		 
		private function stopEraserTool(e:Event):void
		{
			CANVAS.removeEventListener(Event.ENTER_FRAME, drawEraserTool);
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
					CANVAS.removeEventListener(Event.ENTER_FRAME, startPencilTool);
					break;

				case "Eraser":
					CANVAS.removeEventListener(Event.ENTER_FRAME, startEraserTool);
					break;
				//case "Text" :
					//CANVAS.removeEventListener(Event.ENTER_FRAME, writeText);
					
				default:
					break;
			}
		}

		private function highlightTool(tool:DisplayObject):void
		{
			tool.visible=true; //Highlights tool in the parameter
		}

		/* Hides the tools in the parameters */

		private function hideTools(tool1:DisplayObject, tool2:DisplayObject):void
		{
			tool1.visible=false;
			tool2.visible=false;
		}

		/**
		*
		* Handles changing the shape size of the brush
		*
		**/
		private function changeShapeSize():void
		{
			/*if (shapeSize.width >= 50)
			{
				shapeSize.width = 1;
				shapeSize.height = 1;
		 
				textformat.size = 16;
			}
			else
			{
				shapeSize.width += 5;
				shapeSize.height=shapeSize.width;
		 
				textformat.size+=5;
			}*/
		}

		/**
		* This method will be called everytime you change a paramater in Resolume.
		*/
		public function paramChanged( event:ChangeEvent ):void 
		{
		  MonsterDebugger.trace(this, "Param Changed: " + event.object, "Interactive Phase");
		  //Check to see if the param was a Boolean
		  //Find the emoji in the array based on the name
		  if(getQualifiedClassName(event.object) == "resolumeCom.parameters::BooleanParameter")
		  {
			//MonsterDebugger.trace(this, "It's a Boolean.", "Interactive Phase");
		  }
		  else
		  {
			switch(event.object)
			{
			  case paramAccel:
				var newAccel:Number = paramAccel.getValue() * 1000;
				
				break;
			  
			  case paramXPos:
				//Move the brush via the x-axis 
				xPos = paramXPos.getValue() * CANVAS.width;
				break;

			  case paramYPos:
				//Move the brush via the y-axis 
				yPos = paramYPos.getValue() * CANVAS.height;
				break;

			  case paramBrushSize:
				//Select a brush size
				
				break;
			  
			  case paramBrushColor:
				//Select a color 
				//var index:int = int( (paramBrushColor.getValue() * 10) ;
				break;

			  default:
				MonsterDebugger.trace(this, event.object);
				break;
			}
		  }
		}

	}
}