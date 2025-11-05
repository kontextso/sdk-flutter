import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hooks_test/flutter_hooks_test.dart';
import 'package:kontext_flutter_sdk/src/utils/use_update.dart';

void main() {
  testWidgets('this is my test', (tester) async {
    var buildCount = 0;

    final result = await buildHook(() {
      buildCount++;
      return useUpdate();
    });

    expect(buildCount, 1);

    final update = result.current;
    await act(() => update());

    expect(buildCount, 2);
  });
}
