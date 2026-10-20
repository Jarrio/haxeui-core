package haxe.ui.backend;

import haxe.ui.Toolkit;
import haxe.ui.core.Component;
import haxe.ui.core.IComponentContainer;
import haxe.ui.events.UIEvent;
import haxe.ui.styles.StyleSheet;
import haxe.ui.styles.elements.RuleElement;
import haxe.ui.validation.InvalidationFlags;

class ScreenBase implements IComponentContainer {
    public var rootComponents:Array<Component> = [];

    private var _options:ToolkitOptions;
    public var options(get, set):ToolkitOptions;
    private function get_options():ToolkitOptions {
        return _options;
    }
    private function set_options(value:ToolkitOptions):ToolkitOptions {
        _options = value;
        return value;
    }

    public var dpi(get, null):Float;
    private function get_dpi():Float {
        return 72;
    }

    public var title(get, set):String;
    private function get_title():String {
        return null;
    }
    private function set_title(s:String):String {
        return s;
    }

    public var width(get, null):Float;
    private function get_width():Float {
        return 0;
    }

    public var height(get, null):Float;
    private function get_height():Float {
        return 0;
    }

    public var actualWidth(get, null):Float;
    private function get_actualWidth():Float {
        return width * Toolkit.scaleX;
    }

    public var actualHeight(get, null):Float;
    private function get_actualHeight():Float {
        return height * Toolkit.scaleY;
    }
    
    public var isRetina(get, null):Bool;
    private function get_isRetina():Bool {
        return false;
    }

    public var topComponent(get, null):Component;
    private function get_topComponent():Component {
        if (rootComponents.length == 0) {
            return null;
        }

        // lets make a little "hack": if the "top" component has
        // 'pointer-events:none' lets assume that it shouldnt
        // be considered "top" 
        var n = rootComponents.length - 1;
        var c = null;
        while (n >= 0) {
            c = rootComponents[n];
            if (c.style == null) {
                break;
            }
            if (c.style.pointerEvents != "none") {
                break;
            }
            n--;
        }
        return c;
    }
    
    public function addComponent(component:Component):Component {
        return component;
    }

    public function removeComponent(component:Component, dispose:Bool = true, invalidate:Bool = true):Component {
        return component;
    }

    public function containsComponent(child:Component):Bool {
        return false;
    }

    private function handleSetComponentIndex(child:Component, index:Int) {
    }

    private function resizeComponent(c:Component) {
        var cx:Null<Float> = null;
        var cy:Null<Float> = null;

        if (c.percentWidth > 0) {
            cx = (this.width * c.percentWidth) / 100;
        }
        if (c.percentHeight > 0) {
            cy = (this.height * c.percentHeight) / 100;
        }
        c.resizeComponent(cx, cy);
    }

    public function refreshStyleRootComponents() {
        for (component in rootComponents) {
            _refreshStyleComponent(component);
        }
    }

    public function resizeRootComponents() {
        for (component in rootComponents) {
            resizeComponent(component);
        }
    }

    @:access(haxe.ui.core.Component)
    private function _refreshStyleComponent(component:Component) {
        for (child in component.childComponents) {
//            child.applyStyle(child.style);
            child.invalidateComponentStyle();
            child.invalidateComponentDisplay();
            _refreshStyleComponent(child);
        }
    }

    // vw, vh and media queries depend only on the screen's size, so a root that resizes for any other reason (its
    // content grew, say) doesn't need its whole subtree restyled.
    private var _styledWidth:Null<Float> = null;
    private var _styledHeight:Null<Float> = null;

    private function _onRootComponentResize(e:UIEvent) {
        if (_styledWidth == null) {
            // A root's first resize is part of its first validation, which builds its styles at the current size.
            _styledWidth = width;
            _styledHeight = height;
            return;
        }
        if (width == _styledWidth && height == _styledHeight) {
            return;
        }
        _styledWidth = width;
        _styledHeight = height;
        refreshSizeDependentStyles();
    }

    // Restyles only the components that a vw, vh or @media rule matches, instead of every component: restyling
    // everything on each size change of a window being dragged took most of the frame. A rule is tested by its
    // selector alone, since a media condition may have just started or stopped holding.
    private function refreshSizeDependentStyles() {
        var rules = Toolkit.styleSheet.sizeDependentRules();
        for (component in rootComponents) {
            _refreshSizeDependentStyles(component, rules, null, null);
        }
    }

    @:access(haxe.ui.core.Component)
    private function _refreshSizeDependentStyles(component:Component, rules:Array<RuleElement>, localStyleSheet:StyleSheet, localRules:Array<RuleElement>) {
        // A component's own style sheet applies to it and its children, as in Component.styleSheet.
        if (component._styleSheet != null && component._styleSheet != localStyleSheet) {
            localStyleSheet = component._styleSheet;
            localRules = localStyleSheet.sizeDependentRules();
        }
        if (_matchesAny(component, rules) || (localRules != null && _matchesAny(component, localRules))) {
            component.invalidateComponentStyle();
            component.invalidateComponentDisplay();
        }
        for (child in component.childComponents) {
            _refreshSizeDependentStyles(child, rules, localStyleSheet, localRules);
        }
    }

    private static function _matchesAny(component:Component, rules:Array<RuleElement>):Bool {
        for (r in rules) {
            if (r.match(component)) {
                return true;
            }
        }
        return false;
    }

    public function invalidateAll(flag:String = InvalidationFlags.ALL) {
        for (c in rootComponents) {
            invalidateChildren(c, flag);
        }
    }

    private function invalidateChildren(c:Component, flag:String = InvalidationFlags.ALL) {
        for (child in c.childComponents) {
            invalidateChildren(child, flag);
        }
        c.invalidateComponent(flag);
    }

    private function onThemeChanged() {
        for (c in rootComponents) {
            onThemeChangedChildren(c);
        }
    }

    @:access(haxe.ui.core.Component)
    private function onThemeChangedChildren(c:Component) {
        for (child in c.childComponents) {
            onThemeChangedChildren(child);
        }
        c.onThemeChanged();
    }

    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private function supportsEvent(type:String):Bool {
        return false;
    }

    private function mapEvent(type:String, listener:UIEvent->Void) {
    }

    private function unmapEvent(type:String, listener:UIEvent->Void) {
    }
}