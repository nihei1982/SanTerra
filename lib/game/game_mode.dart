enum GameMode {
  normal,
  infinity;

  String get label => switch (this) {
        GameMode.normal => 'NORMAL',
        GameMode.infinity => 'INFINITY',
      };

  String get description => switch (this) {
        GameMode.normal => '上限到達でゲームオーバー',
        GameMode.infinity => '壺が深くなり続け、スクロール可',
      };
}
