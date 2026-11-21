"""
Crea el acceso directo CARL-HES.lnk de la carpeta EJECUTABLE (requiere: pip install pylnk3).

El acceso directo abre CARL-HES\\CARL-HES.exe con una ruta relativa: ejecuta
cmd.exe /c start "" "%CD%\\CARL-HES\\CARL-HES.exe" sin carpeta de inicio, de modo que
Windows usa como carpeta actual la del propio acceso directo. Así funciona desde
cualquier ubicación y no guarda rutas personales.

Uso: python crear_acceso_directo.py "ruta\\de\\EJECUTABLE\\CARL-HES.lnk"
"""
import sys
from datetime import datetime

import pylnk3

destino = sys.argv[1] if len(sys.argv) > 1 else 'CARL-HES.lnk'
lnk = pylnk3.create(destino)
lnk.link_flags.IsUnicode = True
lnk.link_info = None
elementos = [pylnk3.RootEntry(pylnk3.ROOT_MY_COMPUTER), pylnk3.DriveEntry('C:')]
for nombre, carpeta in (('Windows', True), ('System32', True), ('cmd.exe', False)):
    e = pylnk3.PathSegmentEntry()
    e.type = pylnk3.TYPE_FOLDER if carpeta else pylnk3.TYPE_FILE
    e.file_size = 0 if carpeta else 323584
    e.modified = e.created = e.accessed = datetime(2024, 1, 1, 8, 0, 0)
    e.short_name = nombre.upper() if carpeta else 'cmd.exe'
    e.full_name = nombre
    elementos.append(e)
lnk.shell_item_id_list = pylnk3.LinkTargetIDList()
lnk.shell_item_id_list.items = elementos
lnk.link_flags.HasArguments = True
lnk.arguments = r'/c start "" "%CD%\CARL-HES\CARL-HES.exe"'
lnk.link_flags.HasName = True
lnk.description = 'Abre CARL-HES'
lnk.link_flags.HasIconLocation = True
lnk.icon = r'C:\Windows\System32\shell32.dll'
lnk.icon_index = 2
lnk.window_mode = pylnk3.WINDOW_MINIMIZED
lnk.save(destino)
print('Acceso directo creado:', destino)
