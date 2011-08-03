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

package com.christiancantrell.components
{
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	
	public class Button extends Sprite
	{
		private const ENABLED_COLOR:uint = 0xffffff;
		private const DISABLED_COLOR:uint = 0x303030;
		private const GRADIENT_COLORS:Array = [0x333333, 0x030608];

		private var _enabled:Boolean;
		private var labelText:String;
		private var buttonLabel:Label;
		
		public function Button(labelText:String, forcedWidth:int = -1, forcedHeight:int = -1)
		{
			super();
			
			this._enabled = true;
			this.labelText = labelText;

			this.drawLabel(ENABLED_COLOR);
			
			var buttonWidth:uint = (forcedWidth == -1) ? this.buttonLabel.textWidth + 6 : forcedWidth;
			var buttonHeight:uint = (forcedHeight == -1) ? this.buttonLabel.textHeight + 6 : forcedHeight;
			
			this.graphics.beginGradientFill(GradientType.LINEAR, GRADIENT_COLORS, [1,1], [0,255]);
			graphics.drawRoundRect(0, 0, buttonWidth, buttonHeight, 5, 5);
			graphics.endFill();
			
			var bevel:BevelFilter = new BevelFilter(2);
			this.filters = [bevel];

			this.placeLabel();
			
			this.mouseChildren = false;
			
			this.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function drawLabel(color:uint):void
		{
			if (this.buttonLabel != null) this.removeChild(this.buttonLabel);
			this.buttonLabel = new Label(labelText, "normal", color);
		}
		
		private function placeLabel():void
		{
			this.buttonLabel.x = (this.width / 2) - (buttonLabel.textWidth / 2);
			this.buttonLabel.y = (this.height / 2) + (buttonLabel.textHeight / 2);
			this.addChild(buttonLabel);
		}
		
		public function set enabled(enabled:Boolean):void
		{
			if (enabled != this._enabled)
			{
				this.drawLabel((enabled) ? ENABLED_COLOR : DISABLED_COLOR);
				this.placeLabel();
				this._enabled = enabled;
			}
		}
		
		private function onClick(e:MouseEvent):void
		{
			if (!this._enabled) e.stopImmediatePropagation();
		}
		
		public function get label():String
		{
			return this.labelText;
		}
	}
}