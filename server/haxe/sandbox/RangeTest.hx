import Ranges;

class RangeTest {
    static function main() {
        var ranges = new Ranges();
        ranges.add(17, 15);
        ranges.print();
        ranges.add(13, 10);
        ranges.print();
        ranges.add(21, 18);
        ranges.print();
        ranges.add(11, 9);
        ranges.print();
        ranges.add(23, 21);
        ranges.print();
        ranges.add(18, 17);
        ranges.print();
        ranges.add(16, 12);
        ranges.print();

        var ranges2 = new Ranges();
        ranges2.add(17, 15);
        ranges2.print();
        ranges2.add(17, 16);
        ranges2.print();
    }
}
