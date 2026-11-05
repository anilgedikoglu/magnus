// İngilizce metinlerde ay / gün / mevsim adları İngilizce basılır ("during Ocak" hatası).
import 'package:flutter_test/flutter_test.dart';
import 'package:magnus_app/core/utils/variable_replacer.dart';

void main() {
  tearDown(() => VariableReplacer.isEn = false);

  test('isEn kapalı: Türkçe ay adı; açık: İngilizce ay/gün adı', () {
    const tr = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    const en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October',
      'November', 'December'];
    final m = DateTime.now().month;

    VariableReplacer.isEn = false;
    expect(VariableReplacer.replace('{{ay_0}}', const {}), tr[m - 1]);

    VariableReplacer.isEn = true;
    expect(VariableReplacer.replace('{{ay_0}}', const {}), en[m - 1]);
    final gun = VariableReplacer.replace('{{gun_0}}', const {});
    expect(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'], contains(gun));
    expect(VariableReplacer.replace('{{ay_2}}', const {}), isNot(anyOf(tr)));
  });
}
