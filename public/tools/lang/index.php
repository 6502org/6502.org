<?php
$file_content = fread(fopen("../../header.html","r"),
filesize("../../header.html"));
echo($file_content);
?>

<TITLE>6502.org: Compilers & Languages</TITLE>
<META name="description" content="High-level language compilers and
interpreters for the 6502 microprocessor.">


<P><FONT SIZE=+1>Cross-Development Software: Compilers & Languages</FONT>
<BR>
<A HREF="../">[Up to Cross-Development Software]</A>
<BR clear=all><P>
High-level languages, both interpreted and compiled.
<P>
<HR>
<BR>
<A NAME="articles"><P><IMG SRC="/images/files/folder_open.gif" height=17 width=20
align=left alt="**">&nbsp;
<B>Articles</B></a>
<UL>
<FONT COLOR=RED><LI><FONT COLOR=BLACK><A
HREF="http://www.dwheeler.com/6502">6502 Language
Implementation Approaches</A> - David Wheeler's pages describe unusual
ways to implement compilers on the 6502 that are possibly more
efficient.</LI></FONT></FONT>
</UL>

<A NAME="compilers"><P><IMG SRC="/images/files/folder_open.gif" height=17 width=20
align=left alt="**">&nbsp;
<B>Compilers</B></a>
<UL>
<FONT COLOR=RED><LI><FONT COLOR=BLACK><A
HREF="http://www.cc65.org">CC65</A> - A descendant
of Small C, this is a freeware C compiler for 6502-based systems from
Ullrich von Bassewitz.</FONT></FONT>

<LI><A href="lcc-1.9-retargetable.tar.gz">LCC 65C816 [lcc-1.9-retargetable.tar.gz]</a> - Toshi Morita has
successfully ported LCC to compile for the 65C816 microprocessor, and this archive contains complete source code for the
compiler along with simple instructions and examples.</li>

<FONT COLOR=RED><LI><FONT COLOR=BLACK><A HREF="http://www.kdef.com/geek/vic/quetz.html">Quetzalcoatl</A> - Brendan Jones created this C compiler which runs under Linux and Win32.
You can download the program from this site, along with an HTML programming manual, and the source code is available by request.</FONT></FONT>
</UL>

<A NAME="interpreters"><IMG SRC="/images/files/folder_open.gif" height=17 width=20
align=left alt="**">&nbsp;
<B>Interpreters</B></a>
<UL><I>
Interpreted languages and other development tools written in native 6502
code can be found in the <a href="../../source/source.htm">Source Code
Repository</a></I>.</UL>
<P>
<FONT SIZE=-1>Last updated February 24, 2004</FONT>
</HTML>


