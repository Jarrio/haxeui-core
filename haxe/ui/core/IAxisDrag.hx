package haxe.ui.core;

/**
    A component that takes drags along one axis itself, such as a slider. A scroll view it's in waits for a touch drag
    that starts on it to move `ScrollView.dragSlop`, then leaves it a drag along that axis and scrolls for one across
    it, as Android's scroll views and seek bars share a drag. A mouse drag that starts on it is always its own.
**/
interface IAxisDrag {
    /** Whether drags along x (`horizontal`) or along y are the component's own. **/
    function dragsAlong(horizontal:Bool):Bool;
}
