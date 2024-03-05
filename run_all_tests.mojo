import tests.test_join
import tests.test_mog

fn main() raises:
    test_join.run_tests()
    test_mog.run_tests()
    print("All tests passed!")