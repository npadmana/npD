module sqlite;

import std.stdio,  std.conv, std.string;
import etc.c.sqlite3;


// Simply execute some SQL code. Does not look at results here, and assumes no callbacks.
void simpleExec(sqlite3 *db, string sql) {
	char *sqlerr;
	auto ret = sqlite3_exec(db, sql.toStringz, null, null, &sqlerr);
	if (ret!=SQLITE_OK) {
		writeln(to!string(sqlerr));
		sqlite3_free(sqlerr);
		throw new Exception("Error creating table");
	}
}

class SL3statement {
	this(sqlite3 *db, string sql) {
		this.db = db;
		auto ret = sqlite3_prepare_v2(db, sql.toStringz, to!int(sql.length), &stmt, null);
		if (ret!=SQLITE_OK) throw new Exception("Error preparing statement");
	}

	void finalize() {
		auto ret = sqlite3_finalize(stmt);
		if (ret!=SQLITE_OK) throw new Exception("Error finalizing statement");
	}	

	int step() {
		return sqlite3_step(stmt);
	}

	void bind(int i, double d) {
		auto ret = sqlite3_bind_double(stmt, i, d);
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}

	void bind(int i, int d) {
		auto ret = sqlite3_bind_int(stmt, i, d);
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}

	void bind(int i, long d) {
		auto ret = sqlite3_bind_int64(stmt, i, d);
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}

	void bind(int i) {
		auto ret = sqlite3_bind_null(stmt, i);
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}

	void bind_zeroblob(int i, int n) {
		auto ret = sqlite3_bind_zeroblob(stmt, i, n);
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}


	void bind(T)(int i, const T *d, ulong n, bool isStatic=true) {
		int ret;
		if (isStatic) {
			ret = sqlite3_bind_blob(stmt, i, d, to!int(n), SQLITE_STATIC);
		} else {
			ret = sqlite3_bind_blob(stmt, i, d, to!int(n), SQLITE_TRANSIENT);
		}
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}

	void bind(T)(int i, const T[] d, bool isStatic=true) {
		int ret;
		int len = to!(int)(d.length*(T.sizeof));
		if (isStatic) {
			ret = sqlite3_bind_blob(stmt, i, d.ptr, len, SQLITE_STATIC);
		} else {
			ret = sqlite3_bind_blob(stmt, i, d.ptr, len, SQLITE_TRANSIENT);
		}
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}

	void bindmany(A...)(A a) {
		foreach (e; a) {
			bind(e[0],e[1]);
		}
	}

	void clear_bindings() {
		auto ret = sqlite3_clear_bindings(stmt);
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}

	void reset() {
		auto ret = sqlite3_reset(stmt);
		if (ret!=SQLITE_OK) {
			if (ret==SQLITE_RANGE) writeln("Range error binding!");
			throw new Exception("Error binding double");
		}
	}


	T get(T:double)(int icol) {
		return sqlite3_column_double(stmt, icol);
	}

	T get(T:int)(int icol) {
		return sqlite3_column_int(stmt, icol);
	}

	T get(T:long)(int icol) {
		return sqlite3_column_int64(stmt, icol);
	}

	T* get(T : T*)(int icol) {
		return cast(T*)(sqlite3_column_blob(stmt, icol));	
	}

	T[] get(T : T[])(int icol) {
		auto n = nbytes(icol)/(T.sizeof);
		T* ptr = get!(T*)(icol);
		T[] ret = ptr[0..n];	
		return ret;
	}

	int nbytes(int icol) {
		return sqlite3_column_bytes(stmt, icol);
	}

	int opApply(int delegate(SL3statement) dg) {
		auto ret = step();
		if (ret == SQLITE_DONE) return 0;
		if (ret != SQLITE_ROW) throw new Exception("Error processing loop");
		auto dgret = dg(this);
		if (dgret) return dgret;
		return opApply(dg);
	}


	private sqlite3_stmt *stmt;
	private sqlite3 *db; 
}

