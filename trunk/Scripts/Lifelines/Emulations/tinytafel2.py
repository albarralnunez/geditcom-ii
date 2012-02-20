#!/usr/bin/python
#
# Lifelines report: tinytafel2.ll
# Author: Wetmore, Eggert
#
# Python/GEDitCOM II conversion: tinytafel2.py
# Author: John A. Nairn

# Load Lifelines Emulation
from lifelines import *
from operator import add,sub,mul,div,mod,neg,eq,ne,lt,gt,le,ge

# Globals
fdate = None
ldate = None
pdate = None
fplace = None
lplace = None
pplace = None
sname = None

# Subroutines
def process_line(person, plist) :
    global sname
    first_in_line(person)
    initial = trim(sname,1)
    if (initial != "_") and (initial != " ") and (sname != "") :
        last = 0
        while person :
            print ".",
            moth = mother(person)
            if moth :
                enqueue(plist, moth)
            last = person
            person = father(person)
            if sname != surname(person) :
                last_in_line(last)
                if person : first_in_line(person)

def first_in_line(person) :
    global sname,pdate,pplace,fdate,fplace
    set_year_place(person)
    fdate = pdate
    fplace = pplace
    sname = surname(person)

def last_in_line(person) :
    global ldate,pdate,lplace,pplace,line_count,fdate,fplace
    global ldatelist,fdatelist,lplacelist,fplacelist
    set_year_place(person)
    ldate = pdate
    lplace = pplace
    line_count = add(line_count,1)
    addtoset(tafelset,person,line_count)
    if strcmp(ldate,"????") and strcmp(fdate,"????") and (int(ldate) > int(fdate)) :
        # reverse order ldate and fdate
        enqueue(ldatelist,fdate)
        enqueue(fdatelist,ldate)
    else :
        # normal order ldate and fdate
        enqueue(ldatelist,ldate)
        enqueue(fdatelist,fdate)
    enqueue(lplacelist,lplace)
    enqueue(fplacelist,fplace)

def set_year_place(person) :
    global pdate,pplace
    yr = year(birth(person))
    if yr == "" :
        yr = year(baptism(person))
    if yr == "" :
        yr = year(death(person))
    if yr == "" :
        yr = year(burial(person))
    if yr == "" :
        yr = "????"
    pdate = yr
    pl = place(birth(person))
    if pl == "" :
        pl = place(baptism(person))
    if pl == "" :
        pl = place(death(person))
    if pl == "" :
        pl = place(burial(person))
    pplace = pl

def write_tafel_header() :
    out("N John Q. Public\n" )          # your name, mandatory
    out("A 1234 North Maple\n" )        # address, 0-5 lines
    out("A Homesville, OX 12345-6789\n")
    out("A USA\n")
    out("T 1 (101) 555-1212\n")         # telephone number
    out("C 19.2 Baud, Unix System\n")   # communications
    out("C Send any Email to:  jqpublic@my.node.address\n")
    out("B SoftRoots/1-101-555-3434\n") # BBS system/phone number
    out("D Unix Operating System\n")    # diskette formats
    out("F LifeLines Genealogy Program for Unix\n")      # file format
    out("R This is a default header, please ignore.\n")  # comments
    out("Z "+d(line_count)+"\n")

def write_tafelset() :
    global tafelset
    (person,index,snum,iter) = forindiset(tafelset)
    while person :
        out(soundex(person)+" ")
        out(getel(ldatelist,index)+":") #moderate interest by default
        out(getel(fdatelist,index)+":")
        out(surname(person))
        lplace = getel(lplacelist,index)
        if lplace : out("\\"+lplace)
        fplace = getel(fplacelist,index)
        if fplace : out("/"+fplace)
        out("\n")
        (person,index,snum) = forindiset(iter)

def write_tafel_trailer() :
    out("W "+date(gettoday())+"\n")

# Preamble
gdoc = ll_init("tinytafel2.ll program")

# Main program
plist = list()
tafelset = indiset()
fdatelist = list()
ldatelist = list()
fplacelist = list()
lplacelist = list()
line_count = 0

person = getindi()
enqueue(plist, person)
person = dequeue(plist)
while person :
    process_line(person, plist)
    person = dequeue(plist)
namesort(tafelset)
write_tafel_header()
write_tafelset()
write_tafel_trailer()

# output result
finish()
