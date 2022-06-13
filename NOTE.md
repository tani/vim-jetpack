# bootstrap無しの場合
- autoload 必要に応じて割り込みで、runtimepath上のファイルを読み込む。
- plugin 常にvimrcのあとに読み込む。
# bootstrap有り(packadd を呼ぶ）場合
- autoload 必要に応じて割り込みで、runtimepath上のファイルを読み込む。
- plugin packaddの直後に読み込む。

----

# autoload の場合
- bootstrap 版
  - vimscript構文  packadd は必要
  - jetpackのluaモジュールは vimscriptを読み込むことで有効になるので、
    - (**) packaddに加えて明示的に読み込む(runtime */jetpack.vim)必要がある。
- bootstrapなし版
  - vimscript構文
    - (*) 明示的にファイルを読み込まなくてもよい
  - jetpackのluaモジュールは vimscriptを読み込むことで有効になるので、
    - 明示的に読み込む(runtime */jetpack.vim)必要がある。

# pluginの場合
- bootstrap 版
  - vimscript構文  packadd は必要
  - jetpackのluaモジュールは vimscriptを読み込むことで有効になるので、
    - (**)  packadd と同時に読み込まれるため、明示しない。
- bootstrapなし版
  - vimscript構文
    - (*) 明示的にファイルを読み込む(runtime */jetpack.vim)必要がある
  - jetpackのluaモジュールは vimscriptを読み込むことで有効になるので、
    - 明示的に読み込む(runtime */jetpack.vim)必要がある。
    
差分: bootstrap なしの方法ときに、一行ファイル読み込みの行が増え、
bootstrapありの方法のときに、一行ファイルの読み込みの行が減ることになる

