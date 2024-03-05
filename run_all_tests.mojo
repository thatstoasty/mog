import tests.test_join
import tests.test_mog
import tests.test_align
import tests.test_size

fn main() raises:
    test_join.run_tests()
    test_mog.run_tests()
    test_align.run_tests()
    test_size.run_tests()
    print("All tests passed!")