//  Adobe(R) Systems Incorporated Source Code License Agreement
//  Copyright(c) 2006-2010 Adobe Systems Incorporated. All rights reserved.
//	
//  Please read this Source Code License Agreement carefully before using
//  the source code.
//	
//  Adobe Systems Incorporated grants to you a perpetual, worldwide, non-exclusive, 
//  no-charge, royalty-free, irrevocable copyright license, to reproduce,
//  prepare derivative works of, publicly display, publicly perform, and
//  distribute this source code and such derivative works in source or 
//  object code form without any attribution requirements.    
//	
//  The name "Adobe Systems Incorporated" must not be used to endorse or promote products
//  derived from the source code without prior written permission.
//	
//  You agree to indemnify, hold harmless and defend Adobe Systems Incorporated from and
//  against any loss, damage, claims or lawsuits, including attorney's 
//  fees that arise or result from your use or distribution of the source 
//  code.
//  
//  THIS SOURCE CODE IS PROVIDED "AS IS" AND "WITH ALL FAULTS", WITHOUT 
//  ANY TECHNICAL SUPPORT OR ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING,
//  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  ALSO, THERE IS NO WARRANTY OF 
//  NON-INFRINGEMENT, TITLE OR QUIET ENJOYMENT.  IN NO EVENT SHALL ADOBE 
//  OR ITS SUPPLIERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOURCE CODE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package
{
	import com.christiancantrell.components.Alert;
	import com.christiancantrell.components.AlertEvent;
	import com.christiancantrell.components.Label;
	import com.christiancantrell.components.TextButton;
	import com.christiancantrell.data.HistoryEntry;
	import com.christiancantrell.data.MySharedObject;
	import com.christiancantrell.utils.Layout;
	import com.christiancantrell.utils.Ruler;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.InterpolationMethod;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.AccelerometerEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.filters.BevelFilter;
	import flash.filters.BlurFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.GroupSpecifier;
	import flash.net.NetConnection;
	import flash.net.NetGroup;
	import flash.net.registerClassAlias;
	import flash.sensors.Accelerometer;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	public class Reversi extends Sprite
	{
		private const WHITE_COLOR:uint        = 0xffffff;
		private const WHITE_COLOR_NAME:String = "White";
		private const BLACK_COLOR:uint        = 0x000000;
		private const BLACK_COLOR_NAME:String = "Black";
		private const BOARD_COLORS:Array      = [0x666666, 0x333333];
		private const BOARD_LINES:uint        = 0x666666;
		private const BACKGROUND_COLOR:uint   = 0x666666;
		private const TITLE_COLOR:uint        = 0xffffff;
		private const TURN_GLOW_COLORS:Array  = [0xffffff, 0x000000];
		private const TITLE:String = "iReverse";
		private const WHITE:Boolean = true;
		private const BLACK:Boolean = false;
		private const PORTRAIT:String = "portrait";
		private const LANDSCAPE:String = "landscape";
		private const SINGLE_PLAYER_MODE:String = "singlePlayerMode";
		private const SINGLE_PLAYER_STRING:String = "Single Player Game";
		private const TWO_PLAYER_MODE:String = "twoPlayerMode";
		private const TWO_PLAYER_STRING:String = "Two Player Game";
		private const NETWORK_PLAY_STRING:String = "Network";
		private const CANCEL_STRING:String = "Cancel";
		private const COMPUTER_COLOR_STRING:String = "Computer Plays ";
		private const SO_KEY:String = "com.christiancantrell.reversi";
		private const HISTORY_KEY:String = "history";
		private const PLAYER_MODE_KEY:String = "playerMode";
		private const COMPUTER_COLOR_KEY:String = "computerColor";
		private const CACHE_AS_BITMAP:Boolean = true;
		private const STONE_EFFECT_INTERVAL:uint = 40;
		private const COMPUTER_WAIT_TIME:uint = 1000; // milliseconds
		
		private var board:Sprite;
		private var stones:Array;
		private var turn:Boolean;
		private var networkMode:Boolean;
		private var pieces:Vector.<Bitmap>;
		private var history:Array;
		private var historyIndex:int;
		private var blackScoreLabel:Label, whiteScoreLabel:Label;
		private var backButton:TextButton, backButton2:TextButton, nextButton:TextButton, nextButton2:TextButton;
		private var blackScore:uint;
		private var whiteScore:uint;
		private var turnFilter:BlurFilter;
		private var ppi:Number;
		private var stoneBevel:BevelFilter;
		private var boardShadow:DropShadowFilter;
		private var titleShadow:DropShadowFilter;
		private var playerMode:String;
		private var computerColor:Boolean;
		private var so:MySharedObject;
		private var stoneEffectTimer:Timer;
		private var computerWaitTimer:Timer;
		private var whiteStoneBitmap:Bitmap;
		private var blackStoneBitmap:Bitmap;
		private var layoutPending:Boolean;
		private var flat:Boolean;
		private var accelerometer:Accelerometer;
		private var reticlePosition:Object;
		private var reticleFilter:GlowFilter;
		private var stageWidth:int;
		private var stageHeight:int;
		private var netConnection:NetConnection;
		private var netGroup:NetGroup;
		
		public function Reversi(ppi:Number = -1)
		{
			super();
			registerClassAlias("com.christiancantrell.data.HistoryEntry", HistoryEntry);
			this.so = MySharedObject.getLocal(SO_KEY);
			this.ppi = (ppi == -1) ? Capabilities.screenDPI : ppi;
			this.playerMode = SINGLE_PLAYER_MODE;
			this.computerColor = WHITE;
			if (!this.loadGame()) this.prepareGame();
			this.initUIComponents();
			this.addEventListener(Event.ADDED, onAddedToDisplayList);
			if (Accelerometer.isSupported)
			{
				this.accelerometer = new Accelerometer();
				this.accelerometer.setRequestedUpdateInterval(1500);
				this.accelerometer.addEventListener(AccelerometerEvent.UPDATE, onAccelerometerUpdated);
			}
		}
		
		private function loadGame():Boolean
		{
			var oldGame:Array = this.so.data[HISTORY_KEY] as Array;
			if (oldGame == null) return false;
			this.history = oldGame;
			var lastEntry:HistoryEntry;
			for (var i:uint = this.history.length; i >= 0; --i)
			{
				if (this.history[i] != null)
				{
					lastEntry = this.history[i] as HistoryEntry;
					this.historyIndex = i;
					break;
				}
			}
			this.turn = lastEntry.turn;
			this.stones = this.deepCopyStoneArray(lastEntry.board);
			this.playerMode = this.so.data[PLAYER_MODE_KEY];
			if (this.playerMode == SINGLE_PLAYER_MODE)
			{
				this.computerColor = this.so.data[COMPUTER_COLOR_KEY];
			}
			this.calculateScore();
			return true;
		}
		
		private function prepareGame():void
		{
			this.history = new Array(60);
			this.historyIndex = -1;
			this.turn = BLACK;  // Black always starts
			this.initStones();
			this.blackScore = 2;
			this.whiteScore = 2;
		}
		
		private function onAddedToDisplayList(e:Event):void
		{
			this.removeEventListener(Event.ADDED, onAddedToDisplayList);
			if (!this.stage.hasEventListener(Event.RESIZE)) this.stage.addEventListener(Event.RESIZE, doLayout);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function initUIComponents():void
		{
			this.titleShadow = new DropShadowFilter(0, 90, 0, 1, 10, 10, 1, 1, false, true);
			this.turnFilter = new BlurFilter(8, 8, 1);
			this.stoneBevel = new BevelFilter(.75, 45, 0xffffff, 1, 0x000000, 1);
			this.boardShadow = new DropShadowFilter(0, 90, 0, 1, 10, 10, 1, 1);
			this.reticleFilter = new GlowFilter(0xffff00);
			this.stoneEffectTimer = new Timer(STONE_EFFECT_INTERVAL);
			this.computerWaitTimer = new Timer(COMPUTER_WAIT_TIME);
			this.layoutPending = false;
		}
		
		private function onAccelerometerUpdated(e:AccelerometerEvent):void
		{
			if (this.getOrientation() != PORTRAIT || this.playerMode != TWO_PLAYER_MODE) return;
			if (!this.flat && e.accelerationZ > .97)
			{
				this.flat = true;
				this.doLayout();
			}
			else if (this.flat && e.accelerationZ < .97)
			{
				this.flat = false;
				this.doLayout();
			}
		}
		
		/**
		 * Lays out the application dynamically based on screen size and DPI.
		 * Public in case it needs to be called by the "host" code (which it
		 * usually won't).
		 **/
		public function doLayout(e:Event = null, stageWidth:int = -1, stageHeight:int = -1):void
		{
			if (this.stoneEffectTimer.running)
			{
				this.layoutPending = true;
				return;
			}
			
			// Remove any children that have already been added.
			while (this.numChildren > 0) this.removeChildAt(0);

			this.stageWidth = (stageWidth == -1)   ? this.stage.stageWidth  : stageWidth;
			this.stageHeight = (stageHeight == -1) ? this.stage.stageHeight : stageHeight;

			if (this.stageWidth == 0 || this.stageHeight == 0) return;
			
			// Draw the background
			var bg:Sprite = new Sprite();
			bg.graphics.beginFill(BACKGROUND_COLOR);
			bg.graphics.drawRect(0, 0, this.stageWidth, this.stageHeight);
			bg.graphics.endFill();
			this.addChild(bg);
			
			// Figure out the size of the board
			var boardSize:uint = Math.min(this.stageWidth, this.stageHeight);
			
			// Figure out the placement of the board
			var boardX:uint, boardY:uint;
			if (boardSize == this.stageWidth)
			{
				boardX = 0;
				boardY = (this.stageHeight - this.stageWidth) / 2;
			}
			else
			{
				boardY = 0;
				boardX = (this.stageWidth - this.stageHeight) / 2;
			}

			// Create the board and place it
			this.board = new Sprite();
			this.board.x = boardX;
			this.board.y = boardY;
			
			// Draw the board's background
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(boardSize, boardSize, 0, 0, 0);
			this.board.graphics.beginGradientFill(GradientType.RADIAL, BOARD_COLORS, [1, 1], [0, 255], matrix, SpreadMethod.PAD, InterpolationMethod.RGB, 0);
			this.board.graphics.drawRect(0, 0, boardSize, boardSize);
			this.board.graphics.endFill();
			this.board.filters = [this.boardShadow];
			
			// Draw cells on board
			var lineSpace:Number = boardSize / 8;
			this.board.graphics.lineStyle(1, BOARD_LINES);
			var linePosition:uint = 0;
			for (var i:uint = 0; i <= 8; ++i)
			{
				linePosition = i * lineSpace;
				if (linePosition == boardSize) linePosition -= 1;
				// Veritcal
				this.board.graphics.moveTo(linePosition, 0);
				this.board.graphics.lineTo(linePosition, boardSize);
				// Horizontal
				this.board.graphics.moveTo(0, linePosition);
				this.board.graphics.lineTo(boardSize, linePosition);
			}

			this.addChild(this.board);

			// Create the stone bitmaps
			var cellSize:uint = (this.board.width / 8); 
			var stoneSize:uint = cellSize - 4;
			var tmpStone:Sprite = new Sprite();
			tmpStone.graphics.beginFill(WHITE_COLOR);
			tmpStone.graphics.drawCircle(stoneSize/2, stoneSize/2, stoneSize/2);
			tmpStone.graphics.endFill();
			tmpStone.filters = [this.stoneBevel];
			var tmpStoneBitmapData:BitmapData = new BitmapData(tmpStone.width, tmpStone.height, true, 0x000000);
			tmpStoneBitmapData.draw(tmpStone);
			this.whiteStoneBitmap = new Bitmap(tmpStoneBitmapData);
			tmpStone = new Sprite();
			tmpStone.graphics.beginFill(BLACK_COLOR);
			tmpStone.graphics.drawCircle(stoneSize/2, stoneSize/2, stoneSize/2);
			tmpStone.graphics.endFill();
			tmpStone.filters = [this.stoneBevel];
			tmpStoneBitmapData = new BitmapData(tmpStone.width, tmpStone.height, true, 0x000000);
			tmpStoneBitmapData.draw(tmpStone);
			this.blackStoneBitmap = new Bitmap(tmpStoneBitmapData);

			this.placeStones();
			if (CACHE_AS_BITMAP) this.board.cacheAsBitmap = true;
			this.board.addEventListener(MouseEvent.CLICK, onBoardClicked);

			var gutterWidth:uint, gutterHeight:uint, scoreSize:uint;
			var newGameButton:TextButton, newGameButton2:TextButton, buttonWidth:Number, buttonHeight:Number, buttonTextSize:uint, title:Label;
			this.backButton2 = null;
			this.nextButton2 = null;
			
			if (this.flat && this.getOrientation() != PORTRAIT) this.flat = false;
			
			if (this.flat) // Head-to-head
			{
				gutterHeight = (this.stageHeight - boardSize) / 2;
				gutterWidth = this.stageWidth;

				// Scores
				scoreSize = gutterHeight * .6;;
				this.blackScoreLabel = new Label(String(this.blackScore), "bold", BLACK_COLOR, "_sans", scoreSize);
				this.whiteScoreLabel = new Label(String(this.whiteScore), "bold", WHITE_COLOR, "_sans", scoreSize);

				buttonWidth = this.stageWidth / 3;
				buttonHeight = Ruler.mmToPixels(8, this.ppi);
				buttonTextSize = Ruler.mmToPixels(5.5, this.ppi);
				
				// Buttons
				this.backButton = new TextButton("BACK", buttonTextSize, true, buttonWidth, buttonHeight);
				this.backButton.addEventListener(MouseEvent.CLICK, this.onBack);
				this.backButton.x = 2;
				this.backButton.y = (this.stageHeight - this.backButton.height) - 1;
				this.addChild(this.backButton);
				
				this.nextButton = new TextButton("NEXT", buttonTextSize, true, buttonWidth, buttonHeight);
				this.nextButton.addEventListener(MouseEvent.CLICK, this.onNext);
				this.nextButton.x = gutterWidth - this.nextButton.width - 2;
				this.nextButton.y = backButton.y;
				this.addChild(this.nextButton);
				
				// Second set of buttons
				this.backButton2 = new TextButton("BACK", buttonTextSize, true, buttonWidth, buttonHeight);
				this.backButton2.rotation = 180;
				this.backButton2.addEventListener(MouseEvent.CLICK, this.onBack);
				this.backButton2.x = this.backButton2.width + 2;
				this.backButton2.y = this.backButton2.height + 2;
				this.addChild(this.backButton2);
				
				this.nextButton2 = new TextButton("NEXT", buttonTextSize, true, buttonWidth, buttonHeight);
				this.nextButton2.rotation = 180;
				this.nextButton2.addEventListener(MouseEvent.CLICK, this.onNext);
				this.nextButton2.x = gutterWidth - 1.5;
				this.nextButton2.y = backButton2.y;
				this.addChild(this.nextButton2);
			}
			else if (this.getOrientation() == PORTRAIT) // Portrait
			{
				gutterHeight = (this.stageHeight - boardSize) / 2;
				gutterWidth = this.stageWidth;

				// Scores
				scoreSize = gutterHeight * .6;;
				this.blackScoreLabel = new Label(String(this.blackScore), "bold", BLACK_COLOR, "_sans", scoreSize);
				this.whiteScoreLabel = new Label(String(this.whiteScore), "bold", WHITE_COLOR, "_sans", scoreSize);

				title = new Label(TITLE, "bold", TITLE_COLOR, "_sans", gutterHeight/4);
				title.filters = [this.titleShadow];
				title.y = title.height + 4;
				Layout.centerHorizontally(title, this.stage);

				buttonWidth = this.stageWidth / 3;
				buttonHeight = Ruler.mmToPixels(8, this.ppi);
				buttonTextSize = Ruler.mmToPixels(5.5, this.ppi);
				
				this.backButton = new TextButton("BACK", buttonTextSize, true, buttonWidth, buttonHeight);
				this.backButton.addEventListener(MouseEvent.CLICK, this.onBack);
				this.backButton.x = 2;
				this.backButton.y = (this.stageHeight - this.backButton.height) - 1;
				this.addChild(this.backButton);
				
				newGameButton = new TextButton("NEW", buttonTextSize, true, buttonWidth - 6, buttonHeight);
				newGameButton.x = (gutterWidth / 2) - (this.backButton.width / 2) + 3;
				newGameButton.y = this.backButton.y;
				newGameButton.addEventListener(MouseEvent.CLICK, onNewGameButtonClicked);
				this.addChild(newGameButton);
				
				this.nextButton = new TextButton("NEXT", buttonTextSize, true, buttonWidth, buttonHeight);
				this.nextButton.addEventListener(MouseEvent.CLICK, this.onNext);
				this.nextButton.x = gutterWidth - this.nextButton.width - 2;
				this.nextButton.y = newGameButton.y;
				this.addChild(this.nextButton);
			}
			else // Landscape
			{
				gutterWidth = (this.stageWidth - boardSize) / 2;
				gutterHeight = this.stageHeight;

				// Scores
				scoreSize = gutterWidth * .75;
				this.blackScoreLabel = new Label(String(this.blackScore), "bold", BLACK_COLOR, "_sans", scoreSize);
				this.whiteScoreLabel = new Label(String(this.whiteScore), "bold", WHITE_COLOR, "_sans", scoreSize);
				
				title = new Label(TITLE, "bold", TITLE_COLOR, "_sans", (gutterWidth/TITLE.length) + 4);
				title.filters = [this.titleShadow];
				title.y = title.height + 4;
				title.x = ((boardX / 2) - (title.width / 2) - 1);

				buttonWidth = gutterWidth - 10;
				buttonHeight = Ruler.mmToPixels(10, this.ppi) + 4;
				buttonTextSize = ((gutterWidth / 3) > 42) ? 42 : ((gutterWidth / 3) - 1);

				newGameButton = new TextButton("NEW", buttonTextSize, true, buttonWidth, buttonHeight);
				newGameButton.x = (this.stageWidth - gutterWidth) + ((gutterWidth - newGameButton.width) / 2);
				newGameButton.y = 5;
				newGameButton.addEventListener(MouseEvent.CLICK, onNewGameButtonClicked);
				this.addChild(newGameButton);

				this.backButton = new TextButton("BACK", buttonTextSize, true, buttonWidth, buttonHeight);
				this.backButton.addEventListener(MouseEvent.CLICK, this.onBack);
				this.backButton.x = (gutterWidth - this.backButton.width) / 2;
				this.backButton.y = (this.stageHeight - this.backButton.height);
				this.addChild(this.backButton);
				
				this.nextButton = new TextButton("NEXT", buttonTextSize, true, buttonWidth, buttonHeight);
				this.nextButton.addEventListener(MouseEvent.CLICK, this.onNext);
				this.nextButton.x = newGameButton.x;
				this.nextButton.y = (this.stageHeight - this.nextButton.height);
				this.addChild(this.nextButton);
			}
			
			if (CACHE_AS_BITMAP)
			{
				if (title != null) title.cacheAsBitmap = true;
				if (newGameButton != null) newGameButton.cacheAsBitmap = true;
				if (newGameButton2 != null) newGameButton2.cacheAsBitmap = true;
				this.backButton.cacheAsBitmap = true;
				if (this.backButton2 != null) this.backButton2.cacheAsBitmap = true;
				this.nextButton.cacheAsBitmap = true;
				if (this.nextButton2 != null) this.nextButton2.cacheAsBitmap = true;
				this.blackScoreLabel.cacheAsBitmap = true;
				this.whiteScoreLabel.cacheAsBitmap = true;
			}
			
			this.evaluateButtons();
			if (title != null) this.addChild(title);
			this.alignScores();
			this.addChild(this.blackScoreLabel);
			this.addChild(this.whiteScoreLabel);
			this.changeTurnIndicator();
		}
		
		private function alignScores():void
		{
			var gutterDimensions:Object = this.getGutterDimensions();
			if (this.flat)
			{
				var usableGutter:uint = gutterDimensions.height - this.backButton.height;
				
				this.whiteScoreLabel.rotation = 180;
				this.whiteScoreLabel.x = (this.stageWidth / 2) + (this.whiteScoreLabel.width / 2);
				this.whiteScoreLabel.y = (gutterDimensions.height / 2) - (this.whiteScoreLabel.height / 2) - 4;
				
				Layout.centerHorizontally(this.blackScoreLabel, this.stage);
				this.blackScoreLabel.y = (this.stageHeight - (this.blackScoreLabel.height / 2)) + 8;
			}
			else if (this.getOrientation() == LANDSCAPE)
			{
				Layout.centerVertically(this.blackScoreLabel, this.stage);
				this.blackScoreLabel.x = (gutterDimensions.width / 2) - (this.blackScoreLabel.textWidth / 2);
				Layout.centerVertically(this.whiteScoreLabel, this.stage);
				this.whiteScoreLabel.x = this.stageWidth - ((gutterDimensions.width / 2) + (this.whiteScoreLabel.textWidth / 2));
			}
			else
			{
				this.blackScoreLabel.y = ((gutterDimensions.height / 2) + (this.blackScoreLabel.textHeight / 2) + 7);
				this.blackScoreLabel.x = ((gutterDimensions.width / 4) - (this.blackScoreLabel.textWidth / 2) - 4);
				
				this.whiteScoreLabel.y = ((gutterDimensions.height / 2) + (this.whiteScoreLabel.textHeight / 2) + 7);
				this.whiteScoreLabel.x = ((gutterDimensions.width) - ((gutterDimensions.width / 4) + (this.blackScoreLabel.textWidth / 2)) + 4);
			}
		}
		
		private function getOrientation():String
		{
			return (this.stageHeight > this.stageWidth) ? PORTRAIT : LANDSCAPE;
		}

		private function getGutterDimensions():Object
		{
			var gutter:Object = new Object();
			var gutterWidth:uint, gutterHeight:uint;
			if (this.getOrientation() == PORTRAIT)
			{
				gutterWidth = this.stageWidth;
				gutterHeight = (this.stageHeight - this.board.width) / 2;
			}
			else
			{
				gutterWidth = (this.stageWidth - this.board.width) / 2;
				gutterHeight = this.stageHeight;
			}
			gutter.width = gutterWidth;
			gutter.height = gutterHeight;
			return gutter;
		}
		
		private function onKeyDown(e:KeyboardEvent):void
		{
			if (this.isAlertShowing()) return;
			if (this.reticlePosition == null && e.keyCode != Keyboard.ENTER)
			{
				switch (e.keyCode)
				{
					case Keyboard.RIGHT:
						this.onNext();
						return;
					case Keyboard.LEFT:
						this.onBack();
						return;
					case Keyboard.UP:
						this.onNewGameButtonClicked(null);
						return;
					case Keyboard.DOWN:
						this.onNewGameButtonClicked(null);
						return;
				}
			}

			if ((this.playerMode == SINGLE_PLAYER_MODE && this.turn == this.computerColor) || this.stoneEffectTimer.running) return;
			
			if (e.keyCode == Keyboard.ENTER) // either starting or finishing a keyboard move
			{
				if (this.reticlePosition == null) // starting
				{
					for (var x:uint = 0; x < 8; ++x)
					{
						for (var y:uint = 0; y < 8; ++y)
						{
							if (this.stones[x][y] == null)
							{
								this.reticlePosition = {"x":x, "y":y};
								this.placeReticleStone();
								return;
							}
						}
					}
				}
				else // finishing
				{
					if (this.findCaptures(this.turn, this.reticlePosition.x, this.reticlePosition.y, false) > 0)
					{
						var me:MouseEvent = new MouseEvent(MouseEvent.CLICK);
						me.localX = this.reticlePosition.x * this.board.width / 8;
						me.localY = this.reticlePosition.y * this.board.width / 8;
						this.board.dispatchEvent(me);
						this.reticlePosition = null;
					}
				}
				return;
			}

			if (this.reticlePosition != null)
			{
				switch (e.keyCode)
				{
					case Keyboard.RIGHT:
						this.moveReticle(this.reticlePosition.x, this.reticlePosition.y, 1, 0);
						break;
					case Keyboard.LEFT:
						this.moveReticle(this.reticlePosition.x, this.reticlePosition.y, -1, 0);
						break;
					case Keyboard.UP:
						this.moveReticle(this.reticlePosition.x, this.reticlePosition.y, 0, -1);
						break;
					case Keyboard.DOWN:
						this.moveReticle(this.reticlePosition.x, this.reticlePosition.y, 0, 1);
						break;
					case Keyboard.ESCAPE:
						this.removePieceFromBoard(this.reticlePosition.x, this.reticlePosition.y);
						this.reticlePosition = null;
						break;
				}
			}
		}
		
		private function moveReticle(reticleX:int, reticleY:int, deltaX:int, deltaY:int):void
		{
			var newX:int = reticleX + deltaX;
			var newY:int = reticleY + deltaY;
			if (newX < 0 && newY == 0)
			{
				this.moveReticle(8, 7, deltaX, deltaY);
				return;
			}
			else if (newX == 8 && newY == 7)
			{
				this.moveReticle(-1, 0, deltaX, deltaY);
				return;
			}
			else if (newX == 0 && newY == -1)
			{
				this.moveReticle(7, 8, deltaX, deltaY);
				return;
			}
			else if (newX == 7 && newY == 8)
			{
				this.moveReticle(0, -1 , deltaX, deltaY);
				return;
			}
			else if (newX < 0)
			{
				this.moveReticle(8, (reticleY - 1), deltaX, deltaY);
				return;
			}
			else if (newX > 7)
			{
				this.moveReticle(-1, (reticleY + 1), deltaX, deltaY);
				return;
			}
			else if (newY < 0)
			{
				this.moveReticle(reticleX - 1, 8, deltaX, deltaY);
				return;
			}
			else if (newY > 7)
			{
				this.moveReticle(reticleX + 1, -1, deltaX, deltaY);
				return;
			}
			if (this.stones[newX][newY] != null)
			{
				this.moveReticle((reticleX + deltaX), (reticleY + deltaY), deltaX, deltaY);
				return;
			}
			this.removePieceFromBoard(this.reticlePosition.x, this.reticlePosition.y);
			this.reticlePosition = {"x":newX, "y":newY};
			this.placeReticleStone();
		}
		
		private function onBack(e:MouseEvent = null, propagateOnNetwork:Boolean = true):void
		{
			if (this.historyIndex == 0) return;
			--this.historyIndex;
			var historyEntry:HistoryEntry = this.history[this.historyIndex] as HistoryEntry;
			this.stones = this.deepCopyStoneArray(historyEntry.board);
			this.turn = historyEntry.turn;
			this.placeStones();
			this.changeTurnIndicator();
			this.onTurnFinished(false, false);
			if (propagateOnNetwork)
			{
				var message:Object = new Object();
				message.type = "history";
				message.direction = "back";
				this.sendNetworkMessage(message);
			}
		}
		
		private function onNext(e:MouseEvent = null, propagateOnNetwork:Boolean = true):void
		{
			if (this.history[this.historyIndex+1] == null) return;
			++this.historyIndex;
			var historyEntry:HistoryEntry = this.history[this.historyIndex] as HistoryEntry;
			this.stones = this.deepCopyStoneArray(historyEntry.board);
			this.turn = historyEntry.turn;
			this.placeStones();
			this.changeTurnIndicator();
			this.onTurnFinished(false, false);
			if (propagateOnNetwork)
			{
				var message:Object = new Object();
				message.type = "history";
				message.direction = "next";
				this.sendNetworkMessage(message);
			}
		}
		
		private function isAlertShowing():Boolean
		{
			for (var i:uint = 0; i < this.stage.numChildren; ++i)
			{
				if (this.stage.getChildAt(i) is Alert) return true;
			}
			return false;
		}
		
		private function getCurrentAlert():Alert
		{
			for (var i:uint = 0; i < this.stage.numChildren; ++i)
			{
				if (this.stage.getChildAt(i) is Alert) return this.stage.getChildAt(i) as Alert;
			}
			return null;
		}
		
		private function onNewGameButtonClicked(e:MouseEvent = null):void
		{
			if (this.isAlertShowing()) return;
			var alert:Alert = new Alert(this.stage, this.ppi);
			alert.addEventListener(AlertEvent.ALERT_CLICKED, onNewGameConfirm);
			alert.show("Confirm", "Do you want to start a new game?", [SINGLE_PLAYER_STRING, TWO_PLAYER_STRING, NETWORK_PLAY_STRING, CANCEL_STRING]);
		}
		
		private function onNewGameConfirm(e:AlertEvent):void
		{
			var alert:Alert = e.target as Alert;
			alert.removeEventListener(AlertEvent.ALERT_CLICKED, onNewGameConfirm);
			if (e.label == CANCEL_STRING) return;
			this.networkMode = false;
			this.deletePersistentData();
			this.onNetworkPlayCanceled();
			if (e.label == TWO_PLAYER_STRING)
			{
				this.playerMode = TWO_PLAYER_MODE;
				this.prepareGame();
				this.placeStones();
				this.changeTurnIndicator();
				this.calculateScore();
				this.evaluateButtons();
			}
			else if (e.label == SINGLE_PLAYER_STRING)
			{
				var newAlert:Alert = new Alert(this.stage, this.ppi);
				newAlert.addEventListener(AlertEvent.ALERT_CLICKED, onComputerColorChosen);
				newAlert.show("Choose a Color",
							  "Choose a color for the computer. Remember, " + BLACK_COLOR_NAME + " always goes first.",
							  [COMPUTER_COLOR_STRING + WHITE_COLOR_NAME, COMPUTER_COLOR_STRING + BLACK_COLOR_NAME, CANCEL_STRING]);
			}
			else if (e.label == NETWORK_PLAY_STRING)
			{
				this.networkMode = true;
				var networkAlert:Alert = new Alert(this.stage, this.ppi);
				networkAlert.addEventListener(AlertEvent.ALERT_CLICKED, onNetworkPlayCanceled);
				networkAlert.show("Searching", "Looking for another player on the network.", [CANCEL_STRING]);
				this.netConnection = new NetConnection();
				this.netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				this.netConnection.connect("rtmfp:");
			}
		}
		
		private function onNetworkPlayCanceled(e:AlertEvent = null):void
		{
			if (e != null)
			{
				var alert:Alert = e.target as Alert;
				alert.removeEventListener(AlertEvent.ALERT_CLICKED, onNetworkPlayCanceled);
			}
			if (this.netGroup != null)
			{
				this.netGroup.close();
				this.netGroup = null;
			}
			if (this.netConnection != null && this.netConnection.connected)
			{
				this.netConnection.close();
				this.netConnection = null;
			}
			this.networkMode = false;
		}
		
		private function onNetStatus(e:NetStatusEvent):void
		{
			switch(e.info.code)
			{
				case "NetConnection.Connect.Success":
					this.setUpGroup();
					break;
				case "NetGroup.Connect.Success":
					// NetGroup successfully set up.
					break;
				case "NetGroup.Neighbor.Connect":
					var networkAlert:Alert = this.getCurrentAlert();
					if (networkAlert != null) networkAlert.close();
					var newAlert:Alert = new Alert(this.stage, this.ppi);
					newAlert.addEventListener(AlertEvent.ALERT_CLICKED, onNetworkColorChosen);
					newAlert.show("Choose a Color",
						"Choose your color. Remember, " + BLACK_COLOR_NAME + " always goes first.",
						[WHITE_COLOR_NAME, BLACK_COLOR_NAME, CANCEL_STRING]);
					break;
				case "NetGroup.Posting.Notify":
					var message:Object = e.info.message;
					if (message.type == "move")
					{
						this.makeMove(message.x, message.y);
					}
					else if (message.type == "setup")
					{
						var alert:Alert = this.getCurrentAlert();
						if (alert != null) alert.close();
						this.setupNetworkGame(message.opponentColor);
					}
					else if (message.type == "history")
					{
						if (message.direction == "back")
						{
							this.onBack(null, false);
						}
						else if (message.direction == "next")
						{
							this.onNext(null, false);
						}
					}
					break;
			}
		}
		
		// TBD: IP address???
		// TBD: Alert if peer is lost
		private function setUpGroup():void
		{
			var groupspec:GroupSpecifier = new GroupSpecifier("iReverse");
			groupspec.postingEnabled = true;
			groupspec.ipMulticastMemberUpdatesEnabled = true;
			groupspec.addIPMulticastAddress("225.225.0.1:30000");
			this.netGroup = new NetGroup(this.netConnection, groupspec.groupspecWithAuthorizations());
			this.netGroup.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}

		private function onNetworkColorChosen(e:AlertEvent):void
		{
			var alert:Alert = e.target as Alert;
			alert.removeEventListener(AlertEvent.ALERT_CLICKED, onNetworkColorChosen);
			if (e.label == CANCEL_STRING)
			{
				this.onNetworkPlayCanceled();
				return;
			}
			var message:Object = new Object();
			message.type = "setup";
			message.opponentColor = e.label;
			message.sender = this.netGroup.convertPeerIDToGroupAddress(this.netConnection.nearID);
			this.sendNetworkMessage(message);
			this.setupNetworkGame((e.label == BLACK_COLOR_NAME) ? WHITE_COLOR_NAME : BLACK_COLOR_NAME);
		}
		
		private function sendNetworkMessage(message:Object):void
		{
			if (!this.networkMode) return;
			if (this.netConnection != null && this.netConnection.connected && this.netGroup != null && this.netGroup.neighborCount > 0)
			{
				message.time = new Date().time;
				this.netGroup.post(message);
			}
		}
		
		private function setupNetworkGame(computerColorString:String):void
		{
			this.playerMode = SINGLE_PLAYER_MODE;
			this.computerColor = (computerColorString == BLACK_COLOR_NAME) ? BLACK : WHITE;
			this.prepareGame();
			this.placeStones();
			this.changeTurnIndicator();
			this.calculateScore();
			this.evaluateButtons();
		}
			
		private function onComputerColorChosen(e:AlertEvent):void
		{
			var alert:Alert = e.target as Alert;
			alert.removeEventListener(AlertEvent.ALERT_CLICKED, onComputerColorChosen);
			if (e.label == CANCEL_STRING) return;
			this.playerMode = SINGLE_PLAYER_MODE;
			this.computerColor = (e.label == COMPUTER_COLOR_STRING + WHITE_COLOR_NAME) ? WHITE : BLACK;
			this.prepareGame();
			this.placeStones();
			this.changeTurnIndicator();
			this.calculateScore();
			this.evaluateButtons();
			if (this.computerColor == BLACK) this.onStartComputerMove();
		}
		
		private function initStones():void
		{
			this.stones = new Array(8);
			for (var i:uint = 0; i < 8; ++i)
			{
				this.stones[i] = new Array(8);
			}
			this.stones[3][3] = WHITE;
			this.stones[4][4] = WHITE;
			this.stones[4][3] = BLACK;
			this.stones[3][4] = BLACK;
			this.saveHistory();
		}
		
		private function saveHistory():void
		{
			++this.historyIndex;
			var historyEntry:HistoryEntry = new HistoryEntry();
			historyEntry.board = this.deepCopyStoneArray(this.stones);
			historyEntry.turn = this.turn;
			this.history[this.historyIndex] = historyEntry;
			for (var i:uint = this.historyIndex + 1; i < 64; ++i)
			{
				this.history[i] = null;
			}
			this.so.data[HISTORY_KEY] = this.history;
			this.so.data[PLAYER_MODE_KEY] = this.playerMode;
			this.so.data[COMPUTER_COLOR_KEY] = this.computerColor;
			this.so.flush();
		}
		
		private function deletePersistentData():void
		{
			this.so.data[HISTORY_KEY] = null;
			this.so.data[PLAYER_MODE_KEY] = null;
			this.so.data[COMPUTER_COLOR_KEY] = null;
			this.so.flush();
		}

		private function placeStones():void
		{
			this.pieces = new Vector.<Bitmap>(64);
			while (this.board.numChildren > 0) this.board.removeChildAt(0);
			var cellSize:Number = (this.board.width / 8); 
			var stoneSize:Number = cellSize - 2;
			for (var x:uint = 0; x < 8; ++x)
			{
				for (var y:uint = 0; y < 8; ++y)
				{
					if (this.stones[x][y] == null) continue;
					this.placeStone(this.stones[x][y], x, y);
				}
			}
			if (this.reticlePosition != null)
			{
				this.placeReticleStone();
			}
			// TBD: Probably remove. This should be happning when the filter is applied.
			if (CACHE_AS_BITMAP) this.board.cacheAsBitmap = true;
		}
		
		private function placeStone(color:Boolean, x:uint, y:uint):void
		{
			this.removePieceFromBoard(x, y);
			var stone:Bitmap = this.getStone(color, x, y);
			this.pieces[this.coordinatesToIndex(x, y)] = stone;
			this.board.addChild(stone);
		}
		
		private function placeThisStone(stone:Bitmap, x:uint, y:uint):void
		{
			this.removePieceFromBoard(x, y);
			this.pieces[this.coordinatesToIndex(x, y)] = stone;
			this.board.addChild(stone);
		}

		private function placeReticleStone():void
		{
			var stone:Bitmap = this.getStone(this.turn, this.reticlePosition.x, this.reticlePosition.y);
			stone.filters = [this.reticleFilter];
			this.placeThisStone(stone, this.reticlePosition.x, this.reticlePosition.y);
		}
		
		private function getStone(color:Boolean, x:uint, y:uint):Bitmap
		{
			var cellSize:Number = (this.board.width / 8); 
			var stone:Bitmap = (color == WHITE) ? new Bitmap(this.whiteStoneBitmap.bitmapData) : new Bitmap(this.blackStoneBitmap.bitmapData);
			stone.x = (x * cellSize) + 2;
			stone.y = (y * cellSize) + 2;
			return stone;
		}
		
		private function removePieceFromBoard(x:uint, y:uint):void
		{
			var index:uint = this.coordinatesToIndex(x, y);
			if (this.pieces[index] != null)
			{
				this.board.removeChild(Bitmap(this.pieces[index]));
				this.pieces[index] = null;
			}
		}
		
		private function coordinatesToIndex(x:uint, y:uint):uint
		{
			return (y * 8) + x;
		}
		
		private function onBoardClicked(e:MouseEvent):void
		{
			if (this.playerMode == SINGLE_PLAYER_MODE && this.turn == this.computerColor) return;
			if (this.stoneEffectTimer.running) return;
			var scaleFactor:uint = this.board.width / 8;
			var x:uint = e.localX / scaleFactor;
			var y:uint = e.localY / scaleFactor;
			this.makeMove(x, y);
			if (this.playerMode == SINGLE_PLAYER_MODE && this.turn == this.computerColor && !this.networkMode)
			{
				this.onStartComputerMove();
			}
		}
		
		private function makeMove(x:uint, y:uint):void
		{
			if (this.stones[x][y] != null) return;
			if (this.findCaptures(this.turn, x, y, true) == 0) return;
			this.placeStone(this.turn, x, y);
			this.stones[x][y] = this.turn;
			this.onTurnFinished(true, true);
			if (this.networkMode)
			{
				var message:Object = new Object();
				message.type = "move";
				message.x = x;
				message.y = y;
				message.sender = this.netGroup.convertPeerIDToGroupAddress(this.netConnection.nearID);
				this.sendNetworkMessage(message);
			}
		}
		
		private function deepCopyStoneArray(stoneArray:Array):Array
		{
			var newStones:Array = new Array(8);
			for (var x:uint = 0; x < 8; ++x)
			{
				newStones[x] = new Array(8);
				for (var y:uint = 0; y < 8; ++y)
				{
					if (stoneArray[x][y] != null) newStones[x][y] = stoneArray[x][y];
				}
			}
			return newStones;
		}
		
		private function findCaptures(turn:Boolean, x:uint, y:uint, turnStones:Boolean, stones:Array = null):uint
		{
			stones = (stones == null) ? this.stones : stones;
			if (stones[x][y] != null) return 0;
			var topLeft:uint     = this.walkPath(turn, x, y, -1, -1, turnStones, stones); // top left
			var top:uint         = this.walkPath(turn, x, y,  0, -1, turnStones, stones); // top
			var topRight:uint    = this.walkPath(turn, x, y,  1, -1, turnStones, stones); // top right
			var right:uint       = this.walkPath(turn, x, y,  1,  0, turnStones, stones); // right
			var bottomRight:uint = this.walkPath(turn, x, y,  1,  1, turnStones, stones); // bottom right
			var bottom:uint      = this.walkPath(turn, x, y,  0,  1, turnStones, stones); // bottom
			var bottomLeft:uint  = this.walkPath(turn, x, y, -1, +1, turnStones, stones); // bottom left
			var left:uint        = this.walkPath(turn, x, y, -1,  0, turnStones, stones); // left
			return (topLeft + top + topRight + right + bottomRight + bottom + bottomLeft + left);
		}
		
		private function walkPath(turn:Boolean, x:uint, y:uint, xFactor:int, yFactor:int, turnStones:Boolean, stones:Array):uint
		{
			// Are we in bounds?
			if (x + xFactor > 7 || x + xFactor < 0 || y + yFactor > 7 || y + yFactor < 0)
			{
				return 0;
			}

			// Is the next squre empty?
			if (stones[x + xFactor][y + yFactor] == null)
			{
				return 0;
			}
			
			var nextStone:Boolean = stones[x + xFactor][y + yFactor];

			// Is the next stone the wrong color?
			if (nextStone != !turn)
			{
				return 0;
			}
			
			// Find the next piece of the same color
			var tmpX:int = x, tmpY:int = y;
			var stoneCount:uint = 0;
			while (true)
			{
				++stoneCount;
				tmpX = tmpX + xFactor;
				tmpY = tmpY + yFactor;
				if (tmpX < 0 || tmpY < 0 || tmpX > 7 || tmpY > 7 || stones[tmpX][tmpY] == null) // Not enclosed
				{
					return 0;
				}
				nextStone = this.stones[tmpX][tmpY];
				if (nextStone == turn) // Capture!
				{
					if (turnStones) this.turnStones(turn, x, y, tmpX, tmpY, xFactor, yFactor, stones);
					return stoneCount - 1;
				}
			}
			return 0;
		}
		
		private function turnStones(turn:Boolean, fromX:uint, fromY:uint, toX:uint, toY:uint, xFactor:uint, yFactor:uint, stones:Array):void
		{
			var nextX:uint = fromX, nextY:uint = fromY;
			var stonesToTurn:Array = new Array();
			while (true)
			{
				nextX = nextX + xFactor;
				nextY = nextY + yFactor;
				stones[nextX][nextY] = turn;
				if (stones == this.stones)
				{
					if (toX != nextX || toY != nextY)
					{
						stonesToTurn.push({turn:turn, x:nextX, y:nextY});
					}
				}
				if (nextX == toX && nextY == toY)
				{
					this.playStoneEffects(stonesToTurn);
					break;
				}
			}
		}
		
		private function playStoneEffects(stonesToTurn:Array):void
		{
			var newStones:Array = new Array(), oldStones:Array = new Array(), newStone:Bitmap, oldStone:Bitmap;
			for each (var stoneToTurn:Object in stonesToTurn)
			{
				var index:uint = this.coordinatesToIndex(stoneToTurn.x, stoneToTurn.y);
				newStone = this.getStone(stoneToTurn.turn, stoneToTurn.x, stoneToTurn.y);
				newStone.alpha = 0;
				this.board.addChild(newStone);
				newStones.push(newStone);
				oldStones.push(this.pieces[index]);
				this.pieces[index] = newStone;
			}
			
			var animate:Function = function():void
			{
				for (var i:uint = 0; i < newStones.length; ++i)
				{
					newStone = newStones[i] as Bitmap;
					oldStone = oldStones[i] as Bitmap;
					
					newStone.alpha += .1;
					oldStone.alpha -= .1;
					
					if (newStone.alpha >= 1)
					{
						board.removeChild(oldStone);
						if (i == newStones.length - 1)
						{
							stoneEffectTimer.stop();
							stoneEffectTimer.removeEventListener(TimerEvent.TIMER, animate);
							if (this.layoutPending)
							{
								this.doLayout();
								this.layoutPending = false;
							}
						}
					}
				}
			};
			stoneEffectTimer.addEventListener(TimerEvent.TIMER, animate);
			this.stoneEffectTimer.start();
		}
		
		private function onTurnFinished(changeTurn:Boolean, saveHistory:Boolean):void
		{
			if (changeTurn) this.changeTurn();
			this.calculateScore();
			if (this.isNextMovePossible(this.turn))
			{
				this.finishTurn(saveHistory);
				return;
			}

			if ((this.blackScore + this.whiteScore) == 64) // All stones played. Game is over.
			{
				var allStonesPlayedAlert:Alert = new Alert(this.stage, this.ppi);
				allStonesPlayedAlert.addEventListener(AlertEvent.ALERT_CLICKED, genericAlertClicked);
				if (this.blackScore == this.whiteScore) // Tie game
				{
					allStonesPlayedAlert.show("Tie Game!", "Good job! You both finished with the exact same number of stones.");
					this.finishTurn(saveHistory);
					return;
				}
				var winner:String = (this.blackScore > this.whiteScore) ? BLACK_COLOR_NAME : WHITE_COLOR_NAME;
				allStonesPlayedAlert.show(winner + " Wins!", "All stones have been played, so the game is over. Well done, " + winner + "!");
				this.finishTurn(saveHistory);
				return;
			}
						
			if (this.blackScore == 0 || this.whiteScore == 0) // All stones captured. Game over.
			{
				var allStonesCapturedAlert:Alert = new Alert(this.stage, this.ppi);
				allStonesCapturedAlert.addEventListener(AlertEvent.ALERT_CLICKED, genericAlertClicked);
				var zeroPlayer:String = (this.blackScore == 0) ? BLACK_COLOR_NAME : WHITE_COLOR_NAME;
				var nonZeroPlayer:String = (this.blackScore != 0) ? BLACK_COLOR_NAME : WHITE_COLOR_NAME;
				allStonesCapturedAlert.show(nonZeroPlayer + " Wins!", nonZeroPlayer + " has captured all of " + zeroPlayer + "'s stones. Well done, " + nonZeroPlayer + "!");
				this.finishTurn(saveHistory);
				return;
			}
			
			if (!this.isNextMovePossible(!this.turn)) // Neither player can make a move. Unusual, but possible. Game is over.
			{
				var noMoreMovesAlert:Alert = new Alert(this.stage, this.ppi);
				noMoreMovesAlert.addEventListener(AlertEvent.ALERT_CLICKED, genericAlertClicked);
				if (this.blackScore == this.whiteScore) // Tie game
				{
					noMoreMovesAlert.show("Tie Game!", "Neither player can make a move, and you both have the exact same number of stones. Good game!");
					this.finishTurn(saveHistory);
					return;
				}
				var defaultWinner:String = (this.blackScore > this.whiteScore) ? BLACK_COLOR_NAME : WHITE_COLOR_NAME;
				noMoreMovesAlert.show(defaultWinner + " Wins!", "Neither player can make a move, therefore the game is over and " + defaultWinner + " wins!");
				this.finishTurn(saveHistory);
				return;
			}

			// Game isn't over, but opponent can't place a stone.
			if (changeTurn) this.changeTurn();
			var noNextMoveAlert:Alert = new Alert(this.stage, this.ppi);
			var side:String = (this.turn == WHITE) ? BLACK_COLOR_NAME : WHITE_COLOR_NAME;
			var otherSide:String = (this.turn != WHITE) ? BLACK_COLOR_NAME : WHITE_COLOR_NAME;
			noNextMoveAlert.addEventListener(AlertEvent.ALERT_CLICKED, onNoNextMovePossible);
			noNextMoveAlert.show("No Move Available", side + " has no possible moves, and therefore must pass. It's still " + otherSide + "'s turn.");
			this.finishTurn(saveHistory);
		}

		private function genericAlertClicked(e:AlertEvent):void
		{
			var alert:Alert = e.target as Alert;
			alert.removeEventListener(AlertEvent.ALERT_CLICKED, genericAlertClicked);
		}
		
		private function finishTurn(saveHistory:Boolean):void
		{
			if (saveHistory) this.saveHistory();
			this.evaluateButtons();
		}
		
		private function onNoNextMovePossible(e:AlertEvent):void
		{
			var alert:Alert = e.target as Alert;
			alert.removeEventListener(AlertEvent.ALERT_CLICKED, onNoNextMovePossible);
			if (this.playerMode == SINGLE_PLAYER_MODE && this.turn == computerColor)
			{
				this.onStartComputerMove();
			}
		}
		
		private function isNextMovePossible(player:Boolean):Boolean
		{
			for (var x:uint = 0; x < 8; ++x)
			{
				for (var y:uint = 0; y < 8; ++y)
				{
					if (this.stones[x][y] != null) continue;
					if (this.findCaptures(player, x, y, false) > 0) return true;
				}
			}
			return false;
		}
		
		private function changeTurn():void
		{
			this.turn = !this.turn;
			this.changeTurnIndicator();
		}
		
		private function changeTurnIndicator():void
		{
			if (this.turn == WHITE)
			{
				this.whiteScoreLabel.filters = null;
				this.blackScoreLabel.filters = [this.turnFilter];
			}
			else
			{
				this.blackScoreLabel.filters = null;
				this.whiteScoreLabel.filters = [this.turnFilter];
			}
		}
		
		private function evaluateButtons():void
		{
			this.backButton.enabled = (this.historyIndex == 0) ? false : true;
			this.nextButton.enabled = (this.history[this.historyIndex+1] == null) ? false : true;
			if (this.backButton2 != null) this.backButton2.enabled = (this.historyIndex == 0) ? false : true;
			if (this.nextButton2 != null) this.nextButton2.enabled = (this.history[this.historyIndex+1] == null) ? false : true;
		}
		
		private function calculateScore():void
		{
			var black:uint = 0;
			var white:uint = 0;
			for (var x:uint = 0; x < this.stones.length; ++x)
			{
				for (var y:uint = 0; y < this.stones[x].length; ++y)
				{
					if (this.stones[x][y] == null)
					{
						continue;
					}
					else if (this.stones[x][y] == WHITE)
					{
						++white;
					}
					else
					{
						++black;
					}
				}
			}
			this.blackScore = black;
			this.whiteScore = white;
			if (this.whiteScoreLabel!= null && this.blackScoreLabel != null)
			{
				this.whiteScoreLabel.update(String(this.whiteScore));
				this.blackScoreLabel.update(String(this.blackScore));
				this.alignScores();
			}
		}

		private function onStartComputerMove():void
		{
			var computerGo:Function = function():void
			{
				if (!stoneEffectTimer.running)
				{
					computerWaitTimer.stop();
					computerWaitTimer.removeEventListener(TimerEvent.TIMER, computerGo);
					calculateMove();
				}
			};
			this.computerWaitTimer.addEventListener(TimerEvent.TIMER, computerGo);
			this.computerWaitTimer.start();
		}
		
		////  Simple triage-based AI. Opt for the best moves first, and the worst moves last. ////
		
		private const TOP_LEFT_CORNER:Array     = [0,0];
		private const TOP_RIGHT_CORNER:Array    = [7,0];
		private const BOTTOM_RIGHT_CORNER:Array = [7,7];
		private const BOTTOM_LEFT_CORNER:Array  = [0,7];
		
		private const TOP_LEFT_X:Array     = [1,1];
		private const TOP_RIGHT_X:Array    = [6,1];
		private const BOTTOM_RIGHT_X:Array = [6,6];
		private const BOTTOM_LEFT_X:Array  = [1,6];

		private const TOP_TOP_LEFT:Array        = [1,0];
		private const TOP_BOTTOM_LEFT:Array     = [0,1];
		private const TOP_TOP_RIGHT:Array       = [6,0];
		private const TOP_BOTTOM_RIGHT:Array    = [7,1];
		private const BOTTOM_TOP_RIGHT:Array    = [7,6];
		private const BOTTOM_BOTTOM_RIGHT:Array = [6,7];
		private const BOTTOM_TOP_LEFT:Array     = [0,6];
		private const BOTTOM_BOTTOM_LEFT:Array  = [1,7];

		private function calculateMove():void
		{
			// Try to capture a corner...
			if (this.findCaptures(this.computerColor, TOP_LEFT_CORNER[0],     TOP_LEFT_CORNER[1],     false) > 0) {this.onFinishComputerMove(TOP_LEFT_CORNER[0],     TOP_LEFT_CORNER[1]);     return;}
			if (this.findCaptures(this.computerColor, TOP_RIGHT_CORNER[0],    TOP_RIGHT_CORNER[1],    false) > 0) {this.onFinishComputerMove(TOP_RIGHT_CORNER[0],    TOP_RIGHT_CORNER[1]);    return;}
			if (this.findCaptures(this.computerColor, BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1], false) > 0) {this.onFinishComputerMove(BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1]); return;}
			if (this.findCaptures(this.computerColor, BOTTOM_LEFT_CORNER[0],  BOTTOM_LEFT_CORNER[1],  false) > 0) {this.onFinishComputerMove(BOTTOM_LEFT_CORNER[0],  BOTTOM_LEFT_CORNER[1]);  return;}

			// If you already own a corner, try to build off it...
			if (this.stones[TOP_LEFT_CORNER[0]][TOP_LEFT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(TOP_LEFT_CORNER[0], TOP_LEFT_CORNER[1], 1, 0, 6)) return;
				if (this.findAdjacentMove(TOP_LEFT_CORNER[0], TOP_LEFT_CORNER[1], 0, 1, 6)) return;
			}
			if (this.stones[TOP_RIGHT_CORNER[0]][TOP_RIGHT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(TOP_RIGHT_CORNER[0], TOP_RIGHT_CORNER[1], -1, 0, 6)) return;
				if (this.findAdjacentMove(TOP_RIGHT_CORNER[0], TOP_RIGHT_CORNER[1], 0, 1, 6)) return;
			}
			if (this.stones[BOTTOM_RIGHT_CORNER[0]][BOTTOM_RIGHT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1], -1, 0, 6)) return;
				if (this.findAdjacentMove(BOTTOM_RIGHT_CORNER[0], BOTTOM_RIGHT_CORNER[1], 0, -1, 6)) return;
			}
			if (this.stones[BOTTOM_LEFT_CORNER[0]][BOTTOM_LEFT_CORNER[1]] == this.computerColor)
			{
				if (this.findAdjacentMove(BOTTOM_LEFT_CORNER[0], BOTTOM_LEFT_CORNER[1], 1, 0, 6)) return;
				if (this.findAdjacentMove(BOTTOM_LEFT_CORNER[0], BOTTOM_LEFT_CORNER[1], 0, -1, 6)) return;
			}
			
			// Try to capture a side piece, but nothing adjacent to a corner
			if (this.findAdjacentMove(TOP_TOP_LEFT[0],        TOP_TOP_LEFT[1],         1,  0, 4)) return;
			if (this.findAdjacentMove(TOP_BOTTOM_RIGHT[0],    TOP_BOTTOM_RIGHT[1],     0,  1, 4)) return;
			if (this.findAdjacentMove(BOTTOM_BOTTOM_RIGHT[0], BOTTOM_BOTTOM_RIGHT[1], -1,  0, 4)) return;
			if (this.findAdjacentMove(BOTTOM_TOP_LEFT[0],     BOTTOM_TOP_LEFT[1],      0, -1, 4)) return;

			// Find the move that captures the most stones (excluding X-squares and squares close to corners)...
			var captureCounts:Array = new Array();
			for (var x:uint = 0; x < 7; ++x)
			{
				for (var y:uint = 0; y < 7; ++y)
				{
					if (this.stones[x][y] != null) continue;
					if ((x == TOP_LEFT_X[0]          && y == TOP_LEFT_X[1]) ||
						(x == TOP_RIGHT_X[0]         && y == TOP_RIGHT_X[1]) ||
						(x == BOTTOM_LEFT_X[0]       && y == BOTTOM_LEFT_X[1]) ||
						(x == BOTTOM_RIGHT_X[0]      && y == BOTTOM_RIGHT_X[1]) ||
						(x == TOP_TOP_LEFT[0]        && y == TOP_TOP_LEFT[1]) ||
						(x == TOP_BOTTOM_LEFT[0]     && y == TOP_BOTTOM_LEFT[1]) ||
						(x == TOP_TOP_RIGHT[0]       && y == TOP_TOP_RIGHT[1]) ||
						(x == TOP_BOTTOM_RIGHT[0]    && y == TOP_BOTTOM_RIGHT[1]) ||
						(x == BOTTOM_TOP_RIGHT[0]    && y == BOTTOM_TOP_RIGHT[1]) ||
						(x == BOTTOM_BOTTOM_RIGHT[0] && y == BOTTOM_BOTTOM_RIGHT[1]) ||
						(x == BOTTOM_TOP_LEFT[0]     && y == BOTTOM_TOP_LEFT[1]) ||
						(x == BOTTOM_BOTTOM_LEFT[0]  && y == BOTTOM_BOTTOM_LEFT[1]))
					{
						continue;
					}
					var captureCount:uint = this.findCaptures(this.computerColor, x, y, false);
					if (captureCount == 0) continue;
					var captureData:Object = new Object();
					captureData.stones = captureCount;
					captureData.x = x;
					captureData.y = y;
					captureCounts.push(captureData);
				}
			}

			if (captureCounts.length > 0)
			{
				captureCounts.sortOn("stones", Array.NUMERIC, Array.DESCENDING);
				var bestMove:Object = captureCounts.pop();
				if (bestMove.stones > 0)
				{
					this.onFinishComputerMove(bestMove.x, bestMove.y);
					return;
				}
			}

			// No choice but to move adjacent to a corner.
			if (this.findCaptures(this.computerColor, TOP_TOP_LEFT[0],        TOP_TOP_LEFT[1],        false)) {this.onFinishComputerMove(TOP_TOP_LEFT[0],        TOP_TOP_LEFT[1]); return;}
			if (this.findCaptures(this.computerColor, TOP_BOTTOM_LEFT[0],     TOP_BOTTOM_LEFT[1],     false)) {this.onFinishComputerMove(TOP_BOTTOM_LEFT[0],     TOP_BOTTOM_LEFT[1]); return;}
			if (this.findCaptures(this.computerColor, TOP_TOP_RIGHT[0],       TOP_TOP_RIGHT[1],       false)) {this.onFinishComputerMove(TOP_TOP_RIGHT[0],       TOP_TOP_RIGHT[1]); return;}
			if (this.findCaptures(this.computerColor, TOP_BOTTOM_RIGHT[0],    TOP_BOTTOM_RIGHT[1],    false)) {this.onFinishComputerMove(TOP_BOTTOM_RIGHT[0],    TOP_BOTTOM_RIGHT[1]); return;}
			if (this.findCaptures(this.computerColor, BOTTOM_TOP_RIGHT[0],    BOTTOM_TOP_RIGHT[1],    false)) {this.onFinishComputerMove(BOTTOM_TOP_RIGHT[0],    BOTTOM_TOP_RIGHT[1]); return;}
			if (this.findCaptures(this.computerColor, BOTTOM_BOTTOM_RIGHT[0], BOTTOM_BOTTOM_RIGHT[1], false)) {this.onFinishComputerMove(BOTTOM_BOTTOM_RIGHT[0], BOTTOM_BOTTOM_RIGHT[1]); return;}
			if (this.findCaptures(this.computerColor, BOTTOM_TOP_LEFT[0],     BOTTOM_TOP_LEFT[1],     false)) {this.onFinishComputerMove(BOTTOM_TOP_LEFT[0],     BOTTOM_TOP_LEFT[1]); return;}
			if (this.findCaptures(this.computerColor, BOTTOM_BOTTOM_LEFT[0],  BOTTOM_BOTTOM_LEFT[1],  false)) {this.onFinishComputerMove(BOTTOM_BOTTOM_LEFT[0],  BOTTOM_BOTTOM_LEFT[1]); return;}
			
			// No choice but to move in one of the x-squares. Worst possible move.
			if (this.findCaptures(this.computerColor, TOP_LEFT_X[0],     TOP_LEFT_X[1],     false)) {this.onFinishComputerMove(TOP_LEFT_X[0],     TOP_LEFT_X[1]); return;}
			if (this.findCaptures(this.computerColor, TOP_RIGHT_X[0],    TOP_RIGHT_X[1],    false)) {this.onFinishComputerMove(TOP_RIGHT_X[0],    TOP_RIGHT_X[1]); return;}
			if (this.findCaptures(this.computerColor, BOTTOM_LEFT_X[0],  BOTTOM_LEFT_X[1],  false)) {this.onFinishComputerMove(BOTTOM_LEFT_X[0],  BOTTOM_LEFT_X[1]); return;}
			if (this.findCaptures(this.computerColor, BOTTOM_RIGHT_X[0], BOTTOM_RIGHT_X[1], false)) {this.onFinishComputerMove(BOTTOM_RIGHT_X[0], BOTTOM_RIGHT_X[1]); return;}
		}
		
		private function findAdjacentMove(x:uint, y:uint, xFactor:int, yFactor:int, depth:uint):Boolean
		{
			var testX:uint = x, testY:uint = y;
			for (var i:uint = 0; i < depth; ++i)
			{
				testX += xFactor;
				testY += yFactor;
				if (this.stones[testX][testY] == null)
				{
					if (this.findCaptures(this.computerColor, testX, testY, false) > 0)
					{
						this.onFinishComputerMove(testX, testY);
						return true;
					}
				}
			}
			return false;
		}
		
		private function onFinishComputerMove(x:uint, y:uint):void
		{
			this.makeMove(x, y);
		}
	}
}