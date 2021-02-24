<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:html="http://www.w3.org/1999/xhtml">

<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
<xsl:strip-space elements="*"/>

<xsl:variable name="sq">'</xsl:variable>
<xsl:variable name="dsq">''</xsl:variable>

<xsl:template match="/">
	<xsl:text>delete from KenPom;</xsl:text>
	<xsl:for-each select="//html:table[@id='ratings-table']">
		<xsl:for-each select=".//html:tr[count(descendant::html:td) = 21]">
			<xsl:text>insert into KenPom (Rnk,Team,Conf,W,L,Pyth) values (</xsl:text>
			<xsl:value-of select="./html:td[position()=1]"/>
			<xsl:text>,'</xsl:text>
			<xsl:call-template name="double-single-quotes">
				<xsl:with-param name="text" select="normalize-space(./html:td[position()=2]/html:a)"/>
			</xsl:call-template>
			<xsl:text>','</xsl:text>
			<xsl:call-template name="double-single-quotes">
				<xsl:with-param name="text" select="normalize-space(./html:td[position()=3]/html:a)"/>
			</xsl:call-template>
			<xsl:text>',</xsl:text>
			<xsl:value-of select="translate(./html:td[position()=4],'-', ',')"/>
			<xsl:text>,</xsl:text>
			<xsl:value-of select="./html:td[position()=5]"/>
			<xsl:text>);</xsl:text>
		</xsl:for-each>
	</xsl:for-each>
	<xsl:text>update KenPom set ncaaTeam = (select ncaaTeam from KenPomMapping where KenPomMapping.Team = KenPom.Team limit 1);</xsl:text>
	<xsl:text>delete from KenPom where W = 0 and L = 0;</xsl:text>
</xsl:template>

<xsl:template match="*">
	<!-- Override the default rule, which would include the rest of the file as text. -->
</xsl:template>

<xsl:template name="double-single-quotes">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, $sq)">
			<xsl:value-of select="substring-before($text, $sq)"/>
			<xsl:value-of select="$dsq"/>
			<xsl:call-template name="double-single-quotes">
				<xsl:with-param name="text" select="substring-after($text, $sq)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
