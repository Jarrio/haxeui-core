package haxe.ui.core;

/**
    Something a scroll view sits in that shares its touch scrolling, as Android's nested scrolling does: a bottom sheet
    holding a list, which rises before the list scrolls and goes down once the list is at its top. Along an axis the
    view scrolls, each step of a touch drag goes to it first (`nestedPreScroll`), then to the view, and what the view
    can't scroll at an end goes back to it (`nestedPostScroll`); it can take the drag's fling as the finger lifts
    (`nestedFling`), and is handed what's left of a fling of the view's that reaches an end (`nestedFlingLeft`).

    Distances and speeds are in the scroll's units, positive as the content moves on: a finger moving up for a
    vertical scroll. Only vertical scrolling shares so far.
**/
interface INestedScroll {
    /** A touch went down in a scroll view inside it: a new drag, which may share. **/
    function nestedScrollStart(vertical:Bool):Void;

    /** A drag's step of `delta`, before the view scrolls: returns how much of it this took. **/
    function nestedPreScroll(vertical:Bool, delta:Float):Float;

    /** What's left of a drag's step that the view couldn't scroll at an end: returns how much of it this took. **/
    function nestedPostScroll(vertical:Bool, delta:Float):Float;

    /** The finger lifted, moving at `velocity`: returns whether this takes the fling, so the view doesn't fling. **/
    function nestedFling(vertical:Bool, velocity:Float):Bool;

    /** A fling of the view's reached an end with `velocity` left, for this to carry on. **/
    function nestedFlingLeft(vertical:Bool, velocity:Float):Void;
}
