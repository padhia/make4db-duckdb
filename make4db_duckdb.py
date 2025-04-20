"make4db provider for DuckDB"

import logging
from argparse import SUPPRESS, ArgumentParser
from dataclasses import dataclass
from functools import cache
from os import environ
from typing import Any, Callable, Iterable, Self, TextIO

from duckdb import DuckDBPyConnection as DBConn
from duckdb import connect  # type: ignore
from make4db.provider import DDL, DbAccess, DbProvider, Feature, SchObj

logger = logging.getLogger(__name__)
__version__ = "0.1.2"


@dataclass
class DuckDbAcc(DbAccess):
    db_path: str
    _conn: DBConn | None = None

    @property
    def conn(self) -> DBConn:
        if self._conn is None:
            self._conn = connect(database=self.db_path)
        return self._conn

    def __enter__(self) -> Self:
        return self

    def __exit__(self, *args: Any, **kwargs: Any) -> None:
        if self._conn is not None:
            self._conn.close()

    def py2sql(self, fn: Callable[[Any, str, bool], DDL], object: str, replace: bool) -> Iterable[str]:
        ddl = fn(self.conn, object, replace)
        if isinstance(ddl, str):
            yield ddl
        else:
            yield from ddl

    def execsql(self, sql: str, output: TextIO) -> None:
        with self.conn.cursor() as csr:
            csr.execute(sql)
            print("\n** Success **\n", file=output)

    def iterdep(self, objs: Iterable[SchObj]) -> Iterable[tuple[SchObj, SchObj]]:
        raise NotImplementedError("DuckDB::iterdep() isn't implemented")

    def drop_except(self, objs: set[SchObj]) -> Iterable[str]:
        schemas = ",".join(f"'{s}'" for s in set(o.sch for o in objs))

        with self.conn.cursor() as csr:
            sql = f"select table_schema, table_name, table_type from information_schema.tables where table_schema in ({schemas})"
            csr.execute(sql)
            for o, t in ((SchObj.make(r[0], r[1]), "VIEW" if r[2] == "VIEW" else "TABLE") for r in csr.fetchall()):
                if o not in objs:
                    yield f"drop {t} {o}"


@dataclass
class DuckDbProvider(DbProvider):
    def dbacc(self, conn_args: dict[str, Any]) -> DuckDbAcc:
        return DuckDbAcc(**conn_args)

    def add_db_args(self, parser: ArgumentParser) -> None:
        default_db = environ.get("DUCKDB")
        g = parser.add_argument_group("database")
        g.add_argument("--db-path", required=default_db is None, default=default_db, help="DuckDB database path")
        g.add_argument(
            "--debug", dest="loglevel", action="store_const", const=logging.DEBUG, default=logging.WARNING, help=SUPPRESS
        )

    def version(self) -> str:
        return __version__

    def name(self) -> str:
        return "duckdb"

    def supports_feature(self, feature: Feature) -> bool:
        return feature == Feature.CreateOrReplace


@cache
def get_provider() -> DbProvider:
    return DuckDbProvider()
