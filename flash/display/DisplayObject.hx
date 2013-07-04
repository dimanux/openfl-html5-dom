package flash.display;
#if js


import flash.accessibility.AccessibilityProperties;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.IBitmapDrawable;
import flash.display.InteractiveObject;
import flash.display.Stage;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.EventPhase;
import flash.filters.BitmapFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Transform;
import flash.utils.Uuid;
import flash.Lib;
import js.html.CanvasElement;
import js.html.DivElement;
import js.html.Element;
import js.Browser;


class DisplayObject extends EventDispatcher implements IBitmapDrawable {
	
	
	private static inline var GRAPHICS_INVALID:Int = 1 << 1;
	private static inline var MATRIX_INVALID:Int = 1 << 2;
	private static inline var MATRIX_CHAIN_INVALID:Int = 1 << 3;
	private static inline var MATRIX_OVERRIDDEN:Int = 1 << 4;
	private static inline var TRANSFORM_INVALID:Int = 1 << 5;
	private static inline var BOUNDS_INVALID:Int = 1 << 6;
	private static inline var RENDER_VALIDATE_IN_PROGRESS:Int = 1 << 10;
	private static inline var ALL_RENDER_FLAGS:Int = GRAPHICS_INVALID | TRANSFORM_INVALID | BOUNDS_INVALID;
	
	public var accessibilityProperties:AccessibilityProperties;
	public var alpha:Float;
	public var blendMode:BlendMode;
	public var cacheAsBitmap:Bool;
	public var filters(get_filters, set_filters):Array<Dynamic>;
	public var height(get_height, set_height):Float;
	public var loaderInfo:LoaderInfo;
	public var mask(get_mask, set_mask):DisplayObject;
	public var mouseX(get_mouseX, never):Float;
	public var mouseY(get_mouseY, never):Float;
	public var name:String;
	public var nmeCombinedVisible(default, set_nmeCombinedVisible):Bool;
	public var parent(default, set_parent):DisplayObjectContainer;
	public var rotation(get_rotation, set_rotation):Float;
	public var scale9Grid:Rectangle;
	public var scaleX(get_scaleX, set_scaleX):Float;
	public var scaleY(get_scaleY, set_scaleY):Float;
	public var scrollRect(get_scrollRect, set_scrollRect):Rectangle;
	public var stage(get_stage, never):Stage;
	public var transform(default, set_transform):Transform;
	public var visible(get_visible, set_visible):Bool;
	public var width(get_width, set_width):Float;
	public var x(get_x, set_x):Float;
	public var y(get_y, set_y):Float;
	
	private var nmeBoundsRect:Rectangle;
	private var nmeFilters:Array<BitmapFilter>;
	private var nmeHeight:Float;
	private var nmeMask:DisplayObject;
	private var nmeMaskingObj:DisplayObject;
	private var nmeRotation:Float;
	private var nmeScaleX:Float;
	private var nmeScaleY:Float;
	private var nmeScrollRect:Rectangle;
	private var nmeVisible:Bool;
	private var nmeWidth:Float;
	private var nmeX:Float;
	private var nmeY:Float;
	
	private var _bottommostSurface(get__bottommostSurface, null):Element;
	private var _boundsInvalid(get__boundsInvalid, never):Bool;
	private var _fullScaleX:Float;
	private var _fullScaleY:Float;
	private var _matrixChainInvalid(get__matrixChainInvalid, never):Bool;
	private var _matrixInvalid(get__matrixInvalid, never):Bool;
	private var _nmeId:String;
	private var _nmeRenderFlags:Int;
	private var _topmostSurface(get__topmostSurface, null):Element;
		
	//scrollRect divs
	private var _srWindow : DivElement;
	private var _srAxes   : DivElement;

	
	public function new() {
		
		super(null);
		
		_nmeId = Uuid.uuid();
		parent = null;
		
		// initialize transform
		this.transform = new Transform(this);
		nmeX =  0.0;
		nmeY = 0.0;
		nmeScaleX = 1.0;
		nmeScaleY = 1.0;
		nmeRotation = 0.0;
		nmeWidth = 0.0;
		nmeHeight = 0.0;
		
		// initialize graphics metadata
		visible = true;
		alpha = 1.0;
		nmeFilters = new Array<BitmapFilter>();
		nmeBoundsRect = new Rectangle();
		
		nmeScrollRect = null;
		nmeMask = null;
		nmeMaskingObj = null;
		nmeCombinedVisible = visible;
		
	}
	
	
	public override function dispatchEvent(event:Event):Bool {
		
		var result = nmeDispatchEvent(event);
		
		if (event.nmeGetIsCancelled()) {
			
			return true;
			
		}
		
		if (event.bubbles && parent != null) {
			
			parent.dispatchEvent(event);
			
		}
		
		return result;
		
	}
	
	
	public function drawToSurface(inSurface:Dynamic, matrix:Matrix, inColorTransform:ColorTransform, blendMode:BlendMode, clipRect:Rectangle, smoothing:Bool):Void {
		
		var oldAlpha = alpha;
		alpha = 1;
		nmeRender(inSurface, clipRect);
		alpha = oldAlpha;
		
	}
	
	
	public function getBounds(targetCoordinateSpace:DisplayObject):Rectangle {
		
		if (_matrixInvalid || _matrixChainInvalid) nmeValidateMatrix();
		if (_boundsInvalid) validateBounds();
		
		var m = nmeGetFullMatrix();
		
		// perhaps inverse should be stored and updated lazily?
		if (targetCoordinateSpace != null) {
			
			// will be null when target space is stage and this is not on stage
			m.concat(targetCoordinateSpace.nmeGetFullMatrix().invert());
			
		}
		
		var rect = nmeBoundsRect.transform(m);	// transform does cloning
		return rect;
		
	}
	
	
	public function getRect(targetCoordinateSpace:DisplayObject):Rectangle {
		
		// should not account for stroke widths, but is that possible?
		return getBounds(targetCoordinateSpace);
		
	}
	
	
	private function getScreenBounds():Rectangle {
		
		if (_boundsInvalid) validateBounds();
		return nmeBoundsRect.clone();
		
	}
	
	
	private inline function getSurfaceTransform(gfx:Graphics):Matrix {
		
		var extent = gfx.nmeExtentWithFilters;
		var fm = nmeGetFullMatrix();
		
		/*
		var tx = fm.tx;
		var ty = fm.ty;
		var nm = new Matrix();
		nm.scale(1/_fullScaleX, 1/_fullScaleY);
		fm = fm.mult(nm);
		fm.tx = tx;
		fm.ty = ty;
		*/
		
		fm.nmeTranslateTransformed(extent.topLeft);
		return fm;
		
	}
	
	
	public function globalToLocal(inPos:Point):Point {
		
		if (_matrixInvalid || _matrixChainInvalid) nmeValidateMatrix();
		return nmeGetFullMatrix().invert().transformPoint(inPos);
		
	}
	
	
	private inline function handleGraphicsUpdated(gfx:Graphics):Void {
		
		nmeInvalidateBounds();
		nmeApplyFilters(gfx.nmeSurface);
		nmeSetFlag(TRANSFORM_INVALID);
		
	}
	
	
	public function hitTestObject(obj:DisplayObject):Bool {
		
		if (obj != null && obj.parent != null && parent != null) {
			
			var currentBounds = getBounds(this);
			var targetBounds = obj.getBounds(this);
			
			return currentBounds.intersects(targetBounds);
			
		}
		
		return false;
		
	}
	
	
	public function hitTestPoint(x:Float, y:Float, shapeFlag:Bool = false):Bool {
		
		var boundingBox = (shapeFlag == null ? true : !shapeFlag);
		
		if (!boundingBox) {
			
			return nmeGetObjectUnderPoint(new Point(x, y)) != null;
			
		} else {
			
			var gfx = nmeGetGraphics();
			
			if (gfx != null) {
				
				var extX = gfx.nmeExtent.x;
				var extY = gfx.nmeExtent.y;
				var local = globalToLocal(new Point(x, y));
				
				if (local.x - extX < 0 || local.y - extY < 0 || (local.x - extX) * scaleX > width || (local.y - extY) * scaleY > height) {
					
					return false;
					
				} else {
					
					return true;
					
				}
				
			}
			
			return false;
			
		}
		
	}
	
	
	private inline function invalidateGraphics():Void {
		
		var gfx = nmeGetGraphics();
		if (gfx != null) gfx.nmeInvalidate();
		
	}
	
	
	public function localToGlobal(point:Point):Point {
		
		if (_matrixInvalid || _matrixChainInvalid) nmeValidateMatrix();
		return nmeGetFullMatrix().transformPoint(point);
		
	}
	
	
	private function nmeAddToStage(newParent:DisplayObjectContainer, beforeSibling:DisplayObject = null):Void {
		
		var gfx = nmeGetGraphics();
		if (gfx == null) return;
		
		if (newParent.nmeGetGraphics() != null) {
			
			Lib.nmeSetSurfaceId(gfx.nmeSurface, _nmeId);
			
			if (beforeSibling != null && beforeSibling.nmeGetGraphics() != null) {
				
				Lib.nmeAppendSurface(gfx.nmeSurface, beforeSibling._bottommostSurface);
				
			} else {
				
				var stageChildren = [];
				
				for (child in newParent.nmeChildren) {
					
					if (child.stage != null) {
						
						stageChildren.push(child);
						
					}
					
				}
				
				if (stageChildren.length < 1) {
					
					Lib.nmeAppendSurface(gfx.nmeSurface, null, newParent._topmostSurface);
					
				} else {
					
					var nextSibling = stageChildren[stageChildren.length - 1];
					var container;
					
					while (Std.is(nextSibling, DisplayObjectContainer)) {
						
						container = cast(nextSibling, DisplayObjectContainer);
						
						if (container.numChildren > 0) {
							
							nextSibling = container.nmeChildren[container.numChildren - 1];
							
						} else {
							
							break;
							
						}
						
					}
					
					if (nextSibling.nmeGetGraphics() != gfx) {
						
						Lib.nmeAppendSurface(gfx.nmeSurface, null, nextSibling._topmostSurface);
						
					} else {
						
						Lib.nmeAppendSurface(gfx.nmeSurface);
						
					}
					
				}
				
			}
			
			Lib.nmeSetSurfaceTransform(gfx.nmeSurface, getSurfaceTransform(gfx));
			
		} else {
			
			if (newParent.name == Stage.NAME) { // only stage is allowed to add to a parent with no context
				
				Lib.nmeAppendSurface(gfx.nmeSurface);
				
			}
			
		}
		
		if (nmeIsOnStage()) {
			this.nmeSrUpdateDivs();			
			var evt = new Event(Event.ADDED_TO_STAGE, false, false);
			dispatchEvent(evt);
			
		}
	}
	
	
	private inline function nmeApplyFilters(surface:CanvasElement):Void {
		
		if (nmeFilters != null) {
			
			for (filter in nmeFilters) {
				
				filter.nmeApplyFilter(surface);
				
			}
			
		} 
		
	}
	
	
	private function nmeBroadcast(event:Event):Void {
		
		nmeDispatchEvent(event);
		
	}
	
	
	private inline function nmeClearFlag(mask:Int):Void {
		
		_nmeRenderFlags &= ~mask;
		
	}
	
	
	private function nmeDispatchEvent(event:Event):Bool {
		
		if (event.target == null) {
			
			event.target = this;
			
		}
		
		event.currentTarget = this;
		return super.dispatchEvent(event);
		
	}
	
	
	private function nmeFireEvent(event:Event):Void {
		
		var stack:Array<InteractiveObject> = [];
		
		if (this.parent != null) {
			
			this.parent.nmeGetInteractiveObjectStack(stack);
			
		}
		
		var l = stack.length;
		
		if (l > 0) {
			
			// First, the "capture" phase ...
			event.nmeSetPhase(EventPhase.CAPTURING_PHASE);
			stack.reverse();
			
			for (obj in stack) {
				
				event.currentTarget = obj;
				obj.nmeDispatchEvent(event);
				
				if (event.nmeGetIsCancelled()) {
					
					return;
					
				}
				
			}
			
		}
		
		// Next, the "target"
		event.nmeSetPhase(EventPhase.AT_TARGET);
		event.currentTarget = this;
		nmeDispatchEvent(event);
		
		if (event.nmeGetIsCancelled()) {
			
			return;
			
		}
		
		// Last, the "bubbles" phase
		if (event.bubbles) {
			
			event.nmeSetPhase(EventPhase.BUBBLING_PHASE);
			stack.reverse();
			
			for (obj in stack) {
				
				event.currentTarget = obj;
				obj.nmeDispatchEvent(event);
				
				if (event.nmeGetIsCancelled()) {
					
					return;
					
				}
				
			}
			
		}
		
	}
	
	
	public inline function nmeGetFullMatrix(localMatrix:Matrix = null):Matrix {
		
		return transform.nmeGetFullMatrix(localMatrix);
		
	}
	
	
	private function nmeGetGraphics():Graphics {
		
		return null;
		
	}
	
	
	private function nmeGetInteractiveObjectStack(outStack:Array<InteractiveObject>):Void {
		
		var io:InteractiveObject = cast this;
		
		if (io != null) {
			
			outStack.push(io);
			
		}
		
		if (this.parent != null) {
			
			this.parent.nmeGetInteractiveObjectStack(outStack);
			
		}
		
	}
	
	
	private inline function nmeGetMatrix():Matrix {
		
		return transform.matrix;
		
	}
	
	
	private function nmeGetObjectUnderPoint(point:Point):DisplayObject {
		
		if (!visible) return null;
		var gfx = nmeGetGraphics();
		
		if (gfx != null) {
			
			gfx.nmeRender ();
			
			var extX = gfx.nmeExtent.x;
			var extY = gfx.nmeExtent.y;
			var local = globalToLocal(point);
			
			if (local.x - extX <= 0 || local.y - extY <= 0 || (local.x - extX) * scaleX > width || (local.y - extY) * scaleY > height) return null;
			
			//switch (stage.nmePointInPathMode) {
				//
				//case USER_SPACE:
					
					if (gfx.nmeHitTest(local.x, local.y)) {
						
						return cast this;
						
					}
				
				//case DEVICE_SPACE:
					//
					//if (gfx.nmeHitTest(local.x * scaleX, local.y * scaleY)) {
					//if (gfx.nmeHitTest(local.x, local.y)) {
						//
						//return cast this;
						//
					//}
				//
			//}
			
		}
		
		return null;
		
	}
	
	
	private inline function nmeGetSurface():CanvasElement {
		
		var gfx = nmeGetGraphics();
		var surface = null;
		
		if (gfx != null) {
			
			surface = gfx.nmeSurface;
			
		}
		
		return surface;
		
	}
	
	
	private inline function nmeInvalidateBounds():Void {
		
		/**
		 * Bounds are invalidated when:
		 * - a child is added or removed from a container
		 * - a child is scaled, rotated, translated, or skewed
		 * - the display of an object changes(graphics changed,
		 * bitmap loaded, textbox resized)
		 * - a child has its bounds invalidated
		 * ---> Invalidates down to stage
		 */
		//** internal **//
		//** FINAL **//
		
		//TODO :: adjust so that parent is only invalidated if it's bounds are changed by this change
		
		nmeSetFlag(BOUNDS_INVALID);
		
		if (parent != null) {
			
			parent.nmeSetFlag(BOUNDS_INVALID);
			
		}
		
	}
	
	
	public function nmeInvalidateMatrix(local:Bool = false):Void {
		
		/**
		 * Matrices are invalidated when:
		 * - the object is scaled, rotated, translated, or skewed
		 * - an object's parent has its matrices invalidated
		 * ---> 	Invalidates up through children
		 */
		
		if (local) {
			
			nmeSetFlag(MATRIX_INVALID); // invalidate the local matrix
			
		} else {
			
			nmeSetFlag(MATRIX_CHAIN_INVALID); // a parent has an invalid matrix
			
		}
		
	}
	
	
	private function nmeIsOnStage():Bool {
		
		var gfx = nmeGetGraphics();
		
		if (gfx != null && Lib.nmeIsOnStage(gfx.nmeSurface)) {
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	public function nmeMatrixOverridden():Void {
		
		nmeX = transform.matrix.tx;
		nmeY = transform.matrix.ty;
		
		nmeSetFlag(MATRIX_OVERRIDDEN);
		nmeSetFlag(MATRIX_INVALID);
		nmeInvalidateBounds();
		
	}
	
	
	private function nmeRemoveFromStage():Void {
		
		var gfx = nmeGetGraphics();
		
		if (gfx != null && Lib.nmeIsOnStage(gfx.nmeSurface)) {
			
			Lib.nmeRemoveSurface(gfx.nmeSurface);
			var evt = new Event(Event.REMOVED_FROM_STAGE, false, false);
			dispatchEvent(evt);
			
		}
		
	}
	
	
	private function nmeRender(inMask:CanvasElement = null, clipRect:Rectangle = null) {
		
		if (!nmeCombinedVisible) return;
		
		var gfx = nmeGetGraphics();
		if (gfx == null) return;
		
		if (_matrixInvalid || _matrixChainInvalid) nmeValidateMatrix();
		
		/*
		var clip0:Point = null;
		var clip1:Point = null;
		var clip2:Point = null;
		var clip3:Point = null;
		if (clipRect != null) {
			var topLeft = clipRect.topLeft;
			var topRight = clipRect.topLeft.clone();
			topRight.x += clipRect.width;
			var bottomRight = clipRect.bottomRight;
			var bottomLeft = clipRect.bottomRight.clone();
			bottomLeft.x -= clipRect.width;
			clip0 = this.globalToLocal(this.parent.localToGlobal(topLeft));
			clip1 = this.globalToLocal(this.parent.localToGlobal(topRight));
			clip2 = this.globalToLocal(this.parent.localToGlobal(bottomRight));
			clip3 = this.globalToLocal(this.parent.localToGlobal(bottomLeft));
		}
		*/
		
		if (gfx.nmeRender(inMask, nmeFilters, 1, 1)) {
			
			handleGraphicsUpdated(gfx);
			
		}
		
		var fullAlpha:Float = (parent != null ? parent.nmeCombinedAlpha : 1) * alpha;
		
		if (inMask != null) {
			
			var m = getSurfaceTransform(gfx);
			Lib.nmeDrawToSurface(gfx.nmeSurface, inMask, m, fullAlpha, clipRect);
			
		} else {
			
			if (nmeTestFlag(TRANSFORM_INVALID)) {
				
				var m = getSurfaceTransform(gfx);
				Lib.nmeSetSurfaceTransform(gfx.nmeSurface, m);
				nmeClearFlag(TRANSFORM_INVALID);
				

				this.nmeSrUpdateDivs();
				// this.nmeUpdateParentNode();
			}
			
			Lib.nmeSetSurfaceOpacity(gfx.nmeSurface, fullAlpha);
			
			/*if (clipRect != null) {
				var rect = new Rectangle();
				rect.topLeft = this.globalToLocal(this.parent.localToGlobal(clipRect.topLeft));
				rect.bottomRight = this.globalToLocal(this.parent.localToGlobal(clipRect.bottomRight));
				Lib.nmeSetSurfaceClipping(gfx.nmeSurface, rect);
			}*/
			
		}

		// this.nmeUpdateParentNode();
		// if (this.nmeScrollRect == null) {
		// 	var pgfx = this.parent.nmeGetGraphics();
		// 	if (pgfx != null && pgfx.nmeSurface.parentNode != gfx.nmeSurface.parentNode) {
		// 		pgfx.nmeSurface.parentNode.appendChild(gfx.nmeSurface);
		// 	}
		// }
		
	}
	
	
	private inline function nmeSetDimensions():Void {
		
		if (scale9Grid != null) {
			
			nmeBoundsRect.width *= nmeScaleX;
			nmeBoundsRect.height *= nmeScaleY;
			nmeWidth = nmeBoundsRect.width;
			nmeHeight = nmeBoundsRect.height;
			
		} else {
			
			nmeWidth = nmeBoundsRect.width * nmeScaleX;
			nmeHeight = nmeBoundsRect.height * nmeScaleY;
			
		}
		
	}
	
	
	private inline function nmeSetFlag(mask:Int):Void {
		
		_nmeRenderFlags |= mask;
		
	}
	
	
	private inline function nmeSetFlagToValue(mask:Int, value:Bool):Void {
		
		if (value) {
			
			_nmeRenderFlags |= mask;
			
		} else {
			
			_nmeRenderFlags &= ~mask;
			
		}
		
	}
	
	
	public inline function nmeSetFullMatrix(inValue:Matrix):Matrix {
		
		return transform.nmeSetFullMatrix(inValue);
		
	}
	
	
	private inline function nmeSetMatrix(inValue:Matrix):Matrix {
		
		transform.nmeSetMatrix(inValue);
		return inValue;
		
	}
	
	
	private inline function nmeTestFlag(mask:Int):Bool {
		
		return (_nmeRenderFlags & mask) != 0;
		
	}
	
	
	private function nmeUnifyChildrenWithDOM(lastMoveObj:DisplayObject = null) {
		
		var gfx = nmeGetGraphics();		

		if (gfx != null && lastMoveObj != null && this != lastMoveObj) {

			var ogfx = lastMoveObj.nmeGetGraphics();
			if (ogfx != null) {
				Lib.nmeSetSurfaceZIndexAfter(
					(this.nmeScrollRect == null ? gfx.nmeSurface : this._srWindow), 
					(
						lastMoveObj.nmeScrollRect == null
							? ogfx.nmeSurface 
							: (
								lastMoveObj == this.parent
									? ogfx.nmeSurface
									: lastMoveObj._srWindow
							)
					)
				);
			}
			
		}
		
		if (gfx == null) {
			
			return lastMoveObj;
			
		} else {
		
			return this;
		}
		
	}
	
	
	private function nmeValidateMatrix():Void {
		
		var parentMatrixInvalid = (_matrixChainInvalid && parent != null);
		
		if (_matrixInvalid || parentMatrixInvalid) {
			
			if (parentMatrixInvalid) parent.nmeValidateMatrix(); // validate parent matrix
			var m = nmeGetMatrix(); // validate local matrix
			
			if (nmeTestFlag(MATRIX_OVERRIDDEN)) {
				
				nmeClearFlag(MATRIX_INVALID);
				
			}
			
			if (_matrixInvalid) {
				
				m.identity(); // update matrix if necessary
				m.scale(nmeScaleX, nmeScaleY); // set scale
			
				// set rotation if necessary
				var rad = nmeRotation * Transform.DEG_TO_RAD;
				if (rad != 0.0) {
					
					m.rotate(rad);
					
				}
				
				m.translate(nmeX, nmeY); // set translation
				nmeSetMatrix(m);
				
			}
			
			var cm = nmeGetFullMatrix();
			var fm = (parent == null ? m : parent.nmeGetFullMatrix(m));
			
			_fullScaleX = fm._sx;
			_fullScaleY = fm._sy;
			
			if (cm.a != fm.a || cm.b != fm.b || cm.c != fm.c || cm.d != fm.d || cm.tx != fm.tx || cm.ty != fm.ty) {
				
				nmeSetFullMatrix(fm);
				nmeSetFlag(TRANSFORM_INVALID);
				
			}
			
			nmeClearFlag(MATRIX_INVALID | MATRIX_CHAIN_INVALID | MATRIX_OVERRIDDEN);
			
		}
		
	}
	
	
	private function setSurfaceVisible(inValue:Bool):Void {
		
		var gfx = nmeGetGraphics();
		
		if (gfx != null && gfx.nmeSurface != null) {
			
			Lib.nmeSetSurfaceVisible(gfx.nmeSurface, inValue);
			
		}
		
	}
	
	
	override public function toString():String {
		
		return "[DisplayObject name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	private function validateBounds():Void {
		
		if (_boundsInvalid) {
			
			var gfx = nmeGetGraphics();
			
			if (gfx == null) {
				
				nmeBoundsRect.x = x;
				nmeBoundsRect.y = y;
				nmeBoundsRect.width = 0;
				nmeBoundsRect.height = 0;
				
			} else {
				
				nmeBoundsRect = gfx.nmeExtent.clone();
				nmeSetDimensions();
				gfx.boundsDirty = false;
				
			}
			
			nmeClearFlag(BOUNDS_INVALID);
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get__bottommostSurface():Element {
		
		var gfx = nmeGetGraphics();
		if (gfx != null) return gfx.nmeSurface;
		
		return null;
		
	}
	
	
	private function get_filters():Array<BitmapFilter> {
		
		if (nmeFilters == null) return [];
		var result = new Array<BitmapFilter>();
		
		for (filter in nmeFilters) {
			
			result.push(filter.clone());
			
		}
		
		return result;
		
	}
	
	
	private inline function get__boundsInvalid():Bool {
		
		var gfx = nmeGetGraphics();
		
		if (gfx == null) {
			
			return nmeTestFlag(BOUNDS_INVALID);
			
		} else {
			
			return nmeTestFlag(BOUNDS_INVALID) || gfx.boundsDirty;
			
		}
		
	}
	
	
	private function set_filters(filters:Array<Dynamic>):Array<Dynamic> {
		
		var oldFilterCount = (nmeFilters == null) ? 0 : nmeFilters.length;
		
		if (filters == null) {
			
			nmeFilters = null;
			if (oldFilterCount > 0) invalidateGraphics();
			
		} else {
			
			nmeFilters = new Array<BitmapFilter>();
			for (filter in filters) nmeFilters.push(filter.clone());
			invalidateGraphics();
			
		}
		
		return filters;
		
	}
	
	
	private function get_height():Float {
		
		if (_boundsInvalid) {
			
			validateBounds();
			
		}
		
		return nmeHeight;
		
	}
	
	
	private function set_height(inValue:Float):Float {
		
		if (_boundsInvalid) validateBounds();
		var h = nmeBoundsRect.height;
		
		if (nmeScaleY * h != inValue) {
			
			if (h == 0) {
				
				// patch to fix recovery from a height of zero
				
				nmeScaleY = 1;
				nmeInvalidateMatrix(true);
				nmeInvalidateBounds();
				h = nmeBoundsRect.height;
				
			}
			
			if (h <= 0) return 0;
			nmeScaleY = inValue / h;
			nmeInvalidateMatrix(true);
			nmeInvalidateBounds();
			
		}
		
		return inValue;
		
	}
	
	
	private function get_mask():DisplayObject {
		
		return nmeMask;
		
	}
	
	
	private function set_mask(inValue:DisplayObject):DisplayObject {
		
		if (nmeMask != null) {
			
			nmeMask.nmeMaskingObj = null;
			
		}
		
		nmeMask = inValue;
		
		if (nmeMask != null) {
			
			nmeMask.nmeMaskingObj = this;
			
		}
		
		return nmeMask;
		
	}
	
	
	private inline function get__matrixChainInvalid():Bool {
		
		return nmeTestFlag(MATRIX_CHAIN_INVALID);
		
	}
	
	
	private inline function get__matrixInvalid():Bool {
		
		return nmeTestFlag(MATRIX_INVALID);
		
	}
	
	
	private function get_mouseX():Float {
		
		return globalToLocal(new Point(stage.mouseX, 0)).x;
		
	}
	
	
	private function get_mouseY():Float {
		
		return globalToLocal(new Point(0, stage.mouseY)).y;
		
	}
	
	
	private function set_nmeCombinedVisible(inValue:Bool):Bool {
		
		if (nmeCombinedVisible != inValue) {
			
			nmeCombinedVisible = inValue;
			setSurfaceVisible(inValue);
			
		}
		
		return nmeCombinedVisible;
		
	}
	
	
	private function set_parent(inValue:DisplayObjectContainer):DisplayObjectContainer {
		
		if (inValue == this.parent) return inValue;
		nmeInvalidateMatrix();
		
		if (this.parent != null) {
			
			this.parent.__removeChild(this);
			this.parent.nmeInvalidateBounds();
			
		}
		
		if (inValue != null) {
			
			inValue.nmeInvalidateBounds();
			
		}
		
		if (this.parent == null && inValue != null) {
			
			this.parent = inValue;
			var evt = new Event(Event.ADDED, true, false);
			dispatchEvent(evt);
			
		} else if (this.parent != null && inValue == null) {
			
			this.parent = inValue;
			var evt = new Event(Event.REMOVED, true, false);
			dispatchEvent(evt);
			
		} else {
			
			this.parent = inValue;
			
		}
		
		return inValue;
		
	}
	
	
	private function get_rotation():Float {
		
		return nmeRotation;
		
	}
	
	
	private function set_rotation(inValue:Float):Float {
		
		if (nmeRotation != inValue) {
			
			nmeRotation = inValue;
			nmeInvalidateMatrix(true);
			nmeInvalidateBounds();
			
		}
		
		return inValue;
		
	}
	
	
	private function get_scaleX():Float {
		
		return nmeScaleX;
		
	}
	
	
	private function set_scaleX(inValue:Float):Float {
		
		if (nmeScaleX != inValue) {
			
			nmeScaleX = inValue;
			nmeInvalidateMatrix(true);
			nmeInvalidateBounds();
			
		}
		
		return inValue;
		
	}
	
	
	private function get_scaleY():Float {
		
		return nmeScaleY;
		
	}
	
	
	private function set_scaleY(inValue:Float):Float {
		
		if (nmeScaleY != inValue) {
			
			nmeScaleY = inValue;
			nmeInvalidateMatrix(true);
			nmeInvalidateBounds();
			
		}
		
		return inValue;
		
	}
	
	
	private function get_scrollRect():Rectangle {
		
		if (nmeScrollRect == null) return null;
		return nmeScrollRect.clone();
		
	}
	
	
	private function set_scrollRect(inValue:Rectangle):Rectangle {
		
		nmeScrollRect = inValue;
		this.nmeSrUpdateDivs();
		return inValue;
		
	}
	
	
	private function get_stage():Stage {
		
		var gfx = nmeGetGraphics();
		
		if (gfx != null) {
			
			return Lib.nmeGetStage();
			
		}
		
		return null;
		
	}
	
	
	private function get__topmostSurface():Element {
		
		var gfx = nmeGetGraphics();
		
		if (gfx != null) {
			
			return gfx.nmeSurface;
			
		}
		
		return null;
		
	}
	
	
	private function set_transform(inValue:Transform):Transform {
		
		this.transform = inValue;
		nmeX = transform.matrix.tx;
		nmeY = transform.matrix.ty;
		nmeInvalidateMatrix(true);
		return inValue;
		
	}
	
	
	private function get_visible():Bool {
		
		return nmeVisible;
		
	}
	
	
	private function set_visible(inValue:Bool):Bool {
		
		if (nmeVisible != inValue) {
			
			nmeVisible = inValue;
			setSurfaceVisible(inValue);
			
		}
		
		return nmeVisible;
		
	}
	
	
	private function get_x():Float {
		
		return nmeX;
		
	}
	
	
	private function set_x(inValue:Float):Float {
		
		if (nmeX != inValue) {
			
			nmeX = inValue;
			nmeInvalidateMatrix(true);
			
			if (parent != null) {
				
				parent.nmeInvalidateBounds();
				
			}
			
		}
		
		return inValue;
		
	}
	
	
	private function get_y():Float {
		
		return nmeY;
		
	}
	
	
	private function set_y(inValue:Float):Float {
		
		if (nmeY != inValue) {
			
			nmeY = inValue;
			nmeInvalidateMatrix(true);
			
			if (parent != null) {
				
				parent.nmeInvalidateBounds();
				
			}
			
		}
		
		return inValue;
		
	}
	
	
	private function get_width():Float {
		
		if (_boundsInvalid) {
			
			validateBounds();
			
		}
		
		return nmeWidth;
		
	}
	
	
	private function set_width(inValue:Float):Float {
		
		if (_boundsInvalid) validateBounds();
		var w = nmeBoundsRect.width;
		
		if (nmeScaleX * w != inValue) {
			
			if (w == 0) {
				
				// patch to fix recovery from a width of zero
				
				nmeScaleX = 1;
				nmeInvalidateMatrix(true);
				nmeInvalidateBounds();
				w = nmeBoundsRect.width;
				
			}
			
			if (w <= 0) return 0;
			nmeScaleX = inValue / w;
			nmeInvalidateMatrix(true);
			nmeInvalidateBounds();
			
		}
		
		return inValue;
		
	}
	
	/**
	* Get this._srWindow
	*
	*/
	public function nmeGetSrWindow () : DivElement {
	    return this._srWindow;
	}//function nmeGetSrWindow()


	/**
	* Update scrollRect divs
	*
	*/
	private function nmeSrUpdateDivs () : Void {
	    var gfx = nmeGetGraphics();
	    if ( gfx == null || parent == null ) return;

	    if (nmeScrollRect == null){
	    	if ( this._srAxes != null && gfx.nmeSurface.parentNode == this._srAxes && this._srWindow.parentNode != null  ) {
	    		this._srWindow.parentNode.replaceChild(gfx.nmeSurface, this._srWindow);
	    	}
	    	return;
    	}

		//create divs
		if ( this._srWindow == null ) {
			this._srWindow = cast Browser.document.createElement('div');
			this._srAxes   = cast Browser.document.createElement('div');

			this._srWindow.style.setProperty("position", "absolute", "");
			this._srWindow.style.setProperty("left", "0px", "");
			this._srWindow.style.setProperty("top", "0px", "");
			this._srWindow.style.setProperty("width", "0px", "");
			this._srWindow.style.setProperty("height", "0px", "");
			this._srWindow.style.setProperty("overflow", "hidden", "");

			this._srAxes.style.setProperty("position", "absolute", "");
			this._srAxes.style.setProperty("left", "0px", "");
			this._srAxes.style.setProperty("top", "0px", "");

			this._srWindow.appendChild(this._srAxes);
		}//if ( divs does not exist )

		var pnt = this.parent.localToGlobal(new Point(this.x, this.y));

		//update div positions
		this._srWindow.style.left   = pnt.x + "px";
		this._srWindow.style.top    = pnt.y + "px";
		this._srWindow.style.width  = nmeScrollRect.width + "px";
		this._srWindow.style.height = nmeScrollRect.height + "px";

		//scroll axes div
		this._srAxes.style.left = (-pnt.x - nmeScrollRect.x) + "px";
		this._srAxes.style.top  = (-pnt.y - nmeScrollRect.y) + "px";

		//add surface to axes div
		if( gfx.nmeSurface.parentNode != this._srAxes && gfx.nmeSurface.parentNode != null ){
			gfx.nmeSurface.parentNode.insertBefore(this._srWindow, gfx.nmeSurface);
			Lib.nmeRemoveSurface(gfx.nmeSurface);
			this._srAxes.appendChild(gfx.nmeSurface);
		}
	}//function nmeSrUpdateDivs()	

}


#end