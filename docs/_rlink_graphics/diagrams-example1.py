# source: https://diagrams.mingrammer.com/docs/getting-started/installation#quick-start

# to build, run from root folder:
#
#   python docs/_rlink_graphics/diagrams-example1.py
#   firefox docs/_graphics/diagrams-example1.svg

from diagrams import Diagram
from diagrams.aws.compute import EC2
from diagrams.aws.database import RDS
from diagrams.aws.network import ELB

with Diagram("Web Service",
             outformat="svg",
             filename="docs/_graphics/diagrams-example1",
             show=False):
    ELB("lb") >> EC2("web") >> RDS("userdb")
