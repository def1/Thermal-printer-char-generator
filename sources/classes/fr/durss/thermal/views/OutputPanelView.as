package fr.durss.thermal.views {
	import com.nurun.structure.environnement.configuration.Config;
	import flash.utils.ByteArray;
	import fr.durss.thermal.graphics.LoadIconGraphic;
	import fr.durss.thermal.graphics.SaveIconGraphic;
	import com.nurun.utils.draw.createRect;
	import flash.display.Shape;
	import fr.durss.thermal.components.TButton;
	import fr.durss.thermal.components.TCheckBox;
	import fr.durss.thermal.components.TInput;
	import fr.durss.thermal.components.TScrollbar;
	import fr.durss.thermal.controler.FrontControler;
	import fr.durss.thermal.events.ViewEvent;
	import fr.durss.thermal.model.Model;
	import fr.durss.thermal.vo.GridData;
	import fr.durss.thermal.vo.Metrics;
	import fr.durss.thermal.vo.Mode;
	import fr.durss.thermal.vo.ZoneData;

	import com.nurun.components.scroll.ScrollPane;
	import com.nurun.components.scroll.scrollable.ScrollableTextField;
	import com.nurun.structure.environnement.label.Label;
	import com.nurun.structure.mvc.model.events.IModelEvent;
	import com.nurun.structure.mvc.views.AbstractView;
	import com.nurun.structure.mvc.views.ViewLocator;
	import com.nurun.utils.pos.PosUtils;
	import com.nurun.utils.string.StringUtils;

	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	
	/**
	 * Displays the right panel with output and some options
	 * 
	 * @author Durss
	 * @date 6 déc. 2014;
	 */
	public class OutputPanelView extends AbstractView {
		
		[Embed(source="../../../../../assets/codeSample.txt", mimeType="application/octet-stream")]
		private var _codeSample:Class;
		
		private var _cbUserDefineCommands:TCheckBox;
		private var _cbCharHeaderCmdCommands:TCheckBox;
		private var _cbFormatCodeCommands:TCheckBox;
		private var _hexaValues:TCheckBox;
		private var _currentData:GridData;
		private var _input:TInput;
		private var _copyBt:TButton;
		private var _currentFormatedData:String;
		private var _textArea:ScrollPane;
		private var _textfield:ScrollableTextField;
		private var _holder:Sprite;
		private var _cbMinimizeParams:TCheckBox;
		private var _cbForceSize:TCheckBox;
		private var _bitmapMode:Boolean;
		private var _cbLineBreak:TCheckBox;
		private var _zoneList:Vector.<ZoneData>;
		private var _cbIncludeZones:TCheckBox;
		private var _saveBt:TButton;
		private var _loadBt:TButton;
		private var _splitter : Shape;
		private var _saveCodeBt : TButton;
		private var _cbMergeSample : TCheckBox;
		
		
		
		
		/* *********** *
		 * CONSTRUCTOR *
		 * *********** */
		/**
		 * Creates an instance of <code>OutputPanelView</code>.
		 */
		public function OutputPanelView() {
			initialize();
		}

		
		
		/* ***************** *
		 * GETTERS / SETTERS *
		 * ***************** */
		/**
		 * Gets if the full size has been forced
		 */
		public function get forceFullSize():Boolean {
			return _cbForceSize.selected;
		}



		/* ****** *
		 * PUBLIC *
		 * ****** */
		/**
		 * Called on model's update
		 */
		override public function update(event:IModelEvent):void {
			var model:Model = event.model as Model;
			_bitmapMode							= model.currentMode == Mode.MODE_BITMAP_DRAW;
			_cbUserDefineCommands.visible		= 
			_cbCharHeaderCmdCommands.visible	= 
			_cbMinimizeParams.visible			= 
			_cbForceSize.visible				= model.currentMode == Mode.MODE_FONT_GLYPH;
			_saveCodeBt.visible					= 
			_cbIncludeZones.visible				= _bitmapMode;
			_cbMergeSample.visible				= _bitmapMode && _zoneList != null && _zoneList.length > 0;
			_input.defaultLabel					= Label.getLabel( _bitmapMode? 'className' : 'charToreplace');
			_input.textfield.restrict			= _bitmapMode? '[a-z][A-Z][0-9]' : '[0-9]';
			_input.textfield.maxChars			= _bitmapMode? 30 : 3;
			_input.clear();
			if(model.currentInputValue != null) {
				_input.value	= model.currentInputValue;
			}
			
			gridDataUpdateHandler();
			computePositions();
		}


		
		
		/* ******* *
		 * PRIVATE *
		 * ******* */
		/**
		 * Initialize the class.
		 */
		private function initialize():void {
			_holder						= addChild(new Sprite()) as Sprite;
			_saveBt						= _holder.addChild(new TButton(Label.getLabel('saveConf'), 'button', new SaveIconGraphic())) as TButton;
			_loadBt						= _holder.addChild(new TButton(Label.getLabel('loadConf'), 'button', new LoadIconGraphic())) as TButton;
			_splitter					= _holder.addChild(createRect(0xff00cccc, 100,1)) as Shape;
			_hexaValues					= _holder.addChild(new TCheckBox(Label.getLabel("hexaValues"))) as TCheckBox;
			_cbUserDefineCommands		= _holder.addChild(new TCheckBox(Label.getLabel("userDefineCmd"))) as TCheckBox;
			_cbCharHeaderCmdCommands	= _holder.addChild(new TCheckBox(Label.getLabel("charHeaderCmd"))) as TCheckBox;
			_cbFormatCodeCommands		= _holder.addChild(new TCheckBox(Label.getLabel("formatCode"))) as TCheckBox;
			_cbMinimizeParams			= _holder.addChild(new TCheckBox(Label.getLabel("minimizeParams"))) as TCheckBox;
			_cbForceSize				= _holder.addChild(new TCheckBox(Label.getLabel("forceSize"))) as TCheckBox;
			_cbLineBreak				= _holder.addChild(new TCheckBox(Label.getLabel("lineBreaks"))) as TCheckBox;
			_cbIncludeZones				= _holder.addChild(new TCheckBox(Label.getLabel("includeZones"))) as TCheckBox;
			_cbMergeSample				= _holder.addChild(new TCheckBox(Label.getLabel('injectSample'))) as TCheckBox;
			_input						= _holder.addChild(new TInput(Label.getLabel('charToreplace'))) as TInput;
			_copyBt						= _holder.addChild(new TButton(Label.getLabel('copyData'))) as TButton;
			_saveCodeBt					= _holder.addChild(new TButton(Label.getLabel('saveCode'))) as TButton;
			_textfield					= new ScrollableTextField('', 'code');
			_textArea					= _holder.addChild(new ScrollPane(_textfield, new TScrollbar(), new TScrollbar())) as ScrollPane;
			
			_copyBt.textBoundsMode					= false;
			_saveCodeBt.textBoundsMode				= false;
			_copyBt.enabled							= false;
			_textfield.autoWrap						= false;
			_textfield.selectable					= true;
			_textArea.autoHideScrollers				= true;
			_cbMergeSample.selected					= false;
			_cbUserDefineCommands.selected			= 
			_cbCharHeaderCmdCommands.selected		= 
			_cbMinimizeParams.selected				= 
			_cbForceSize.selected					= 
			_cbLineBreak.selected					= 
			_cbIncludeZones.selected				= 
			_cbFormatCodeCommands.selected			= true;
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			_hexaValues.addEventListener(Event.CHANGE, updateFormHandler);
			_cbUserDefineCommands.addEventListener(Event.CHANGE, updateFormHandler);
			_cbCharHeaderCmdCommands.addEventListener(Event.CHANGE, updateFormHandler);
			_cbFormatCodeCommands.addEventListener(Event.CHANGE, updateFormHandler);
			_cbMinimizeParams.addEventListener(Event.CHANGE, updateFormHandler);
			_cbForceSize.addEventListener(Event.CHANGE, updateFormHandler);
			_cbLineBreak.addEventListener(Event.CHANGE, updateFormHandler);
			_cbIncludeZones.addEventListener(Event.CHANGE, updateFormHandler);
			_cbMergeSample.addEventListener(Event.CHANGE, updateFormHandler);
			_input.addEventListener(Event.CHANGE, updateFormHandler);
			_input.addEventListener(FocusEvent.FOCUS_OUT, focusOutInputHandler);
			_copyBt.addEventListener(MouseEvent.CLICK, clickButtonHandler);
			_saveBt.addEventListener(MouseEvent.CLICK, clickButtonHandler);
			_loadBt.addEventListener(MouseEvent.CLICK, clickButtonHandler);
			_saveCodeBt.addEventListener(MouseEvent.CLICK, clickButtonHandler);
			ViewLocator.getInstance().addEventListener(ViewEvent.GRID_DATA_UPDATE, gridDataUpdateHandler);
			ViewLocator.getInstance().addEventListener(ViewEvent.ZONE_LIST_UPDATE, zoneListUpdateHandler);
		}
		
		/**
		 * Forces a refresh of the data
		 */
		private function updateFormHandler(event:Event):void {
			if(event.target == _cbForceSize) {
				FrontControler.getInstance().forceSizeChange(_cbForceSize.selected);
			}else{
				gridDataUpdateHandler();
			}
		}
		
		/**
		 * Called when input looses focus
		 */
		private function focusOutInputHandler(event:FocusEvent):void {
			if(_bitmapMode) FrontControler.getInstance().setInputParam(_input.text);
			if(_input.text.length == 0 || _input.text == _input.defaultLabel || _bitmapMode) return;
			
			var char:int = parseInt(_input.text);
			if(isNaN(char)) char = 33;
			if(char < 32) char = 33;
			if(char > 126) char = 126;
			_input.text = char.toString();
			FrontControler.getInstance().setInputParam(_input.text);
			
		}
		
		/**
		 * Called when the stage is available.
		 */
		private function addedToStageHandler(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			stage.addEventListener(Event.RESIZE, computePositions);
			computePositions();
		}
		
		/**
		 * Resize and replace the elements.
		 */
		private function computePositions(event:Event = null):void {
			y = Metrics.TOP_BAR_HEIGHT;
			
			var margin:int = 10;
			_holder.x = _holder.y = margin;
			var items:Array = [_saveBt, _splitter, _hexaValues, _cbUserDefineCommands, _cbCharHeaderCmdCommands, _cbFormatCodeCommands, _cbMinimizeParams, _cbForceSize, _cbLineBreak, _cbIncludeZones, _cbMergeSample, _input, _copyBt, _textArea];
			var i:int, len:int;
			len = items.length;
			for(i = 0; i < len; ++i) {
				if(!DisplayObject(items[i]).visible) {
					items.splice(i, 1);
					i--;
					len--;
				}
			}
			PosUtils.vPlaceNext(10, items);
			_input.width = Math.max(_hexaValues.width, _cbUserDefineCommands.width, _cbCharHeaderCmdCommands.width, _cbFormatCodeCommands.width, _cbLineBreak.width, _cbIncludeZones.width, _cbMergeSample.width);
			
			PosUtils.hCenterIn(_copyBt, _input);
			if(_bitmapMode) {
				var space:int = (_input.width - _saveCodeBt.width - _copyBt.width) / 3;
				_copyBt.x = space;
				_saveCodeBt.x = _input.width - _saveCodeBt.width - space;
				_saveCodeBt.y = _copyBt.y;
			}
			
			_loadBt.y			= _saveBt.y;
			_saveBt.x			= Math.round(_loadBt.width + margin);
			_splitter.width		= _input.width;
			_textArea.width		= _input.width;
			_textArea.height	= stage.stageHeight - y - _textArea.y - margin * 2;
			_textArea.validate();
			
			graphics.clear();
			graphics.beginFill(0xffffff, 1);
			graphics.drawRect(0, 0, width + margin * 2, height + margin * 2);
			graphics.beginFill(0, .2);
			graphics.drawRect(-2, 0, 2, height + margin * 2);
			graphics.beginFill(0, .1);
			graphics.drawRect(-4, 0, 2, height + margin * 2);
			
			_textArea.graphics.clear();
			_textArea.graphics.beginFill(0xf5f5f5, 1);
			_textArea.graphics.drawRect(0, 0, _textArea.width, _textArea.height);
			
			x = stage.stageWidth - width + 4;
		}
		
		/**
		 * Formats a byte value
		 */
		private function formatByte(data:int):String {
			var prefix:String = _hexaValues.selected? "0x" : "";
			var base:int = _hexaValues.selected? 16 : 10;
			var value:String = data.toString(base);
			if(_hexaValues.selected) value = StringUtils.toDigit(value);
			if(_cbFormatCodeCommands.selected && !_bitmapMode) {
				return "printer.writeBytes(" + prefix + value + ");";
			}else{
				return prefix + value;
			}
		}
		
		/**
		 * Called when grid data updates.
		 * Refreshes the output code.
		 */
		private function gridDataUpdateHandler(event:ViewEvent = null):void {
			if(event != null) _currentData = event.data as GridData;
			if(_currentData == null)return;
			
			_currentData.data.position = 0;
			var result:Array = [], b:int;
			
			if(_bitmapMode) {
				//Generate for bitmap
				while (_currentData.data.bytesAvailable) {
					b = _currentData.data.readUnsignedByte();
					result.push( formatByte(b) );
					if(_cbLineBreak.selected && _currentData.data.position%38 == 0) result.push('\n'); 
				}
				_currentFormatedData = result.join(',').replace(/,\n,/gi, ',\n');
				
				var varType:String = 'const PROGMEM ';
				if(_cbFormatCodeCommands.selected) {
					var name:String		 =_input.text != _input.defaultLabel && _input.text.length > 0? _input.text : 'bitmap';
					var formated:String	 = '#ifndef _' + name + '_h_\n';
					formated			+= '#define _' + name + '_h_\n';
					formated			+= '\n';
					formated			+= '#define ' + name + '_width  '+_currentData.areaSource.width+'\n';
					formated			+= '#define ' + name + '_height '+_currentData.areaSource.height+'\n\n';
					//Add zones infos
					if(_cbIncludeZones.selected && _zoneList != null && _zoneList.length > 0) {
						var i:int, len:int, zone:ZoneData, zName:String, bitOffset:Number, byteOffset:Number, bitSubOffset:int, bitLength:int;
						varType = '';
						len = _zoneList.length;
						for(i = 0; i < len; ++i) {
							zone		= _zoneList[i];
							zName		= zone.name.replace(' ', '_').split(/\n|\r/)[0];//Keep only first line of the name
							bitOffset	= (zone.area.x - _currentData.areaSource.x)%_currentData.areaSource.width + (zone.area.y - _currentData.areaSource.y) * _currentData.areaSource.width;
							byteOffset	= Math.floor(bitOffset/8);
							bitSubOffset= 7 - (bitOffset%8);
							bitLength	= zone.area.width * zone.area.height;
							formated	+= '//Define ' + zName + ' zone bounds (' + zone.area.width + 'x' + zone.area.height + 'px)\n';
							formated	+= '#define ' + zName + '_byteOffset '+byteOffset+'		//Byte chunk where the zone starts\n';
							formated	+= '#define ' + zName + '_bitSubOffset '+bitSubOffset+' 		//Bit of the byte chunk where the zone starts (left/hight bit=7 right/low bit=0)\n';
//							formated	+= '#define ' + zName + '_bitLength '+bitLength+'		//Size of the zone in bits\n';
							formated	+= '#define ' + zName + '_bitWidth '+zone.area.width+'			//Width of the zone in bits\n\n';
						}
					}
					formated			+= 'static '+varType+'uint8_t ' + name + '_data[] = {';
					if(_cbLineBreak.selected) formated += '\n';
					formated			+= _currentFormatedData;
					if(_cbLineBreak.selected) formated += '\n';
					formated			+= '};\n';
					formated			+= '#endif\n';
					_currentFormatedData = formated;
				}
				
				if(_cbMergeSample.selected) {
					var data:ByteArray = new _codeSample();
					_currentFormatedData += "\n\n"+data.readUTFBytes(data.bytesAvailable).replace(/(\r|\n){2}/gi, '\n');
				}else{
					_currentFormatedData += "\n\n";
					_currentFormatedData += '// See this file for an example on how to make use\n';
					_currentFormatedData += '// of the "Zones" feature to merge an image with another\n';
					_currentFormatedData += '// '+Config.getUncomputedPath("mergeSampleFile");
				}
				
			}else{
				//Generate for fonts
				if(_cbUserDefineCommands.selected) {
					result.push('//Enable user defined chars');
					result.push(formatByte(27), formatByte(37), formatByte(1));
					result.push('');
				}
				
				if(_cbCharHeaderCmdCommands.selected) {
					result.push('//Define custom char header');
					var char:int = _input.text == _input.defaultLabel? 33 : parseInt(_input.text);
					if(isNaN(char)) char = 33;
					
					result.push(formatByte(27),
								formatByte(38),
								formatByte(height/8),
								formatByte(char),
								formatByte(width));
					result.push('');
				}
				
				result.push('//Custom char data');
				while (_currentData.data.bytesAvailable) {
					b = _currentData.data.readUnsignedByte();
					result.push( formatByte(b) );
				}
				
				_currentFormatedData = result.join("\n");
				
				if(_cbMinimizeParams.selected && _cbFormatCodeCommands.selected) {
					//Concatenate 4 consecutive commands into one
					_currentFormatedData = _currentFormatedData.replace(/printer.writeBytes\(([^)]{1,4})\);\nprinter.writeBytes\(([^)]{1,4})\);\nprinter.writeBytes\(([^)]{1,4})\);\nprinter.writeBytes\(([^)]{1,4})\);/gmi, 'printer.writeBytes($1, $2, $3, $4);');
					//Concatenate 3 consecutive commands into one
					_currentFormatedData = _currentFormatedData.replace(/printer.writeBytes\(([^)]{1,4})\);\nprinter.writeBytes\(([^)]{1,4})\);\nprinter.writeBytes\(([^)]{1,4})\);/gmi, 'printer.writeBytes($1, $2, $3);');
					//Concatenate 2 consecutive commands into one
					_currentFormatedData = _currentFormatedData.replace(/printer.writeBytes\(([^)]{1,4})\);\nprinter.writeBytes\(([^)]{1,4})\);/gmi, 'printer.writeBytes($1, $2);');
				}
			}
			
			_textfield.text = _currentFormatedData;
			_textArea.validate();
			_copyBt.enabled = _currentFormatedData.length > 0;
		}
		
		/**
		 * Called when a zone is created/deleted
		 */
		private function zoneListUpdateHandler(event:ViewEvent):void {
			_zoneList				= event.data as Vector.<ZoneData>;
			_cbMergeSample.visible	= _bitmapMode && _zoneList != null && _zoneList.length > 0;
			gridDataUpdateHandler();
			computePositions();
		}
		
		/**
		 * Called when a button is clicked
		 */
		private function clickButtonHandler(event:MouseEvent):void {
			if(event.currentTarget == _saveBt) {
				FrontControler.getInstance().save();
			}else if(event.currentTarget == _copyBt){
				Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, _textfield.text);
			}else if(event.currentTarget == _loadBt){
				FrontControler.getInstance().load();
			}else if(event.currentTarget == _saveCodeBt) {
				FrontControler.getInstance().saveCode(_currentFormatedData, _input.text);
			}
		}
		
	}
}