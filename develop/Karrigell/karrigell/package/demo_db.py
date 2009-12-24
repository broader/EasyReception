import os

import sqlalchemy
from sqlalchemy.engine.url import URL
from sqlalchemy import *
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relation, backref

db_engine = None

def init(config):
    global db_engine
    db_path = os.path.join(config.data_dir,"demos.sqlite")
    if not os.path.exists(db_path):
        db_engine = create_engine(URL(drivername="sqlite",
                                  database=db_path))
        Base.metadata.create_all(db_engine)

Base = declarative_base()
class Blog(Base):
    __tablename__ = "blogs"
    id = Column(Integer, primary_key=True)
    parent_id = Column(Integer,ForeignKey("blogs.id"))
    comments = relation("Blog", remote_side=parent_id)
    author = Column(Unicode)
    title = Column(Unicode)
    text = Column(Unicode)
    date = Column(DateTime)
    
    def __repr__(self):
        return "<Blog> %s:%s %s" % (self.title,self.author,
                                    self.date.isoformat())

class CalenderTask(Base):
    __tablename__ = "calender_tasks"
    id = Column(Integer, primary_key=True)
    content = Column(Unicode)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    
class QuizQuiz(Base):
    __tablename__ = "quiz_quizes"
    id = Column(Integer, primary_key=True)
    name = Column(Unicode)
    category_id = Column(Integer,ForeignKey("quiz_categories.id"))
    question = Column(Unicode)
    answer = Column(Boolean)
    
    def __init__(self,name,question,answer):
        self.name = name
        self.question = question
        self.answer = answer

class QuizCategory(Base):
    __tablename__ = "quiz_categories"
    id = Column(Integer, primary_key=True)
    name = Column(Unicode)
    quizes = relation("QuizQuiz", backref="category")
    
    def __init__(self,name):
        self.name = name
        
def db_session():
    return sessionmaker(bind=db_engine)()