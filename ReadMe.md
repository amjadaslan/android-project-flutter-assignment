# android-project-flutter-assignment

### 1. What class is used to implement the controller pattern in this library? What features does it allow the developer to control?

- snappingSheetController class, which allows us to control the position of the snapping sheet.

### 2. The library allows the bottom sheet to snap into position with various different animations. What parameter controls this behavior?

- snappingCurve & snappingDuration parameters which are available in SnappingPosition instance are responsible for such behavior.

### 3. Name one advantage of InkWell over the latter and one advantage of GestureDetector over the first

- Inkwell provides a ripple effect tap which GestureDetector doesn't have.
- GestureDetector does not require a Material Widget as an ancestor while Inkwell does.
