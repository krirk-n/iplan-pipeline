from abc import ABC, abstractmethod
from pyArango.connection import Connection
# Carl's note:
# it took me quite some effort to figure out how to install  abc and pyArango correctly
# follow the link below to create and activate virtual environment: 
# https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/
# and install abc and pyArango in the virtual environment

#from config import Config
#from logger import logger

class ArangoDB(ABC):
    def __init__(self):
        self.conn = None
        self.db = None
    def get_db(self):
        return self.db
    def get_collection(self, name):
        return self.get_db()[name]
    def sort_docs(self, docs, key="name"):
        return sorted([d for d in docs], key=lambda d: d[key].lower())
    def query_one(self, aql, **kwargs):
        kwargs.update({'singleResult': True})
        return self.query(aql, **kwargs)
    def query(self, aql, **kwargs):
        singleResult = kwargs.pop('singleResult', False)
        toList = kwargs.pop('toList', False)
        result = self.get_db().AQLQuery(aql, **kwargs)
        if singleResult is True:
            return next(result, None)
        elif toList is True:
            return [doc for doc in result]
        return result
    @abstractmethod
    def connect(self):
        pass
class UserDB(ArangoDB):
    def connect(self):
        #logger.debug("user url: %s", Config.get("arango", "user_db_url"))
        self.conn = Connection(
            #arangoURL=Config.get("arango", "user_db_url"),
            #username=Config.get("arango", "user_db_username"),
            #password=Config.get("arango", "user_db_password"))
            # arangoURL="http://44.231.24.74:8529", 
            arangoURL="http://52.40.108.10:8529",
            username="lem",
            password="Q2ySWjcXaz!zs5YsmYN")
        #self.db = self.conn[Config.get("arango", "user_db_schema")]
        self.db = self.conn["lem_user_data"]
    def get_maps_collection(self):
        # return self.get_collection("maps_nightly") # arangoURL="http://44.231.24.74:8529",
        return self.get_collection("maps_prod") # arangoURL="http://52.40.108.10:8529",
    def get_targets_collection(self):
        return self.get_collection("indicator_targets")
    def get_submissions_collection(self):
        return self.get_collection("submissions_prod")
    def get_submission(self, map_id, **kwargs):
        return self.get_submissions_collection().fetchDocument(map_id,**kwargs)
    def get_submission_documents(self):
        return self.get_submissions_collection().fetchAll(rawResults=True)
    def get_map(self, map_id, **kwargs):
        return self.get_maps_collection().fetchDocument(map_id, **kwargs)
    def get_maps():
        # TODO: implement some generic fetch all maps?
        pass

class DataDB(ArangoDB):
    def connect(self):
        #logger.debug("data url: %s", Config.get("arango", "data_db_url"))
        self.conn = Connection(
            # arangoURL="http://44.231.24.74:8529",
            arangoURL="http://52.40.108.10:8529",
            username="lem",
            password="Q2ySWjcXaz!zs5YsmYN")
        self.db = self.conn["lem_geo_data"]
    def get_lucs_collection(self):
        return self.get_collection("lucs")
    def get_indicators_collection(self):
        return self.get_collection("indicators")
    def get_multipliers_collection(self):
        return self.get_collection(multipliers)
    def get_lucs(self):
        return self.sort_docs(self.get_lucs_collection().fetchAll(rawResults=True))
    def get_indicators(self):
        return self.sort_docs(self.get_indicators_collection().fetchAll(rawResults=True))
    def get_multipliers(self):
        return [d for d in self.get_multipliers_collection().fetchAll(rawResults=True)]
