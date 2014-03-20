module ini;

public import ini.inifile;
version(SQLITE3) {
	public import ini.sqliteini;
}
