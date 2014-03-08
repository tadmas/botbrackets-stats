<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:html="http://www.w3.org/1999/xhtml">

<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
<xsl:strip-space elements="*"/>

<xsl:param name="GAMENO"/>
<xsl:variable name="sq">'</xsl:variable>
<xsl:variable name="dsq">''</xsl:variable>

<xsl:template match="/">
	<xsl:for-each select="html:html/html:body/html:div[@id='contentArea']">
		<xsl:text>insert into Games(ncaaGameNo,teamA,teamAScore,teamB,teamBScore,gameDate,location) values (</xsl:text>
			<xsl:value-of select="$GAMENO"/>

			<xsl:for-each select="//html:td[text()='1st Half']">
				<xsl:for-each select="../../html:tr[(position() = 2) or (position() = 3)]">
					<xsl:text>,'</xsl:text>
					<xsl:choose>
						<xsl:when test="./html:td/html:a[starts-with(@href,'/team/')]">
							<xsl:call-template name="double-single-quotes">
								<xsl:with-param name="text" select="normalize-space(./html:td/html:a)"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="double-single-quotes">
								<xsl:with-param name="text" select="normalize-space(./html:td)" />
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:text>',</xsl:text>
					<xsl:value-of select="./html:td[position()=last()]"/>
				</xsl:for-each>
			</xsl:for-each>

			<xsl:text>,'</xsl:text>
			<xsl:for-each select="//html:td[contains(text(),'Game Date:')]">
				<xsl:value-of select="../html:td[position()=last()]"/>
			</xsl:for-each>

			<xsl:text>','</xsl:text>
			<xsl:for-each select="//html:td[contains(text(),'Location:')]">
				<xsl:call-template name="double-single-quotes">
					<xsl:with-param name="text" select="translate(../html:td[position()=last()],'\','')"/>
				</xsl:call-template>
			</xsl:for-each>

			<xsl:text>'</xsl:text>
		<xsl:text>);</xsl:text>

		<xsl:text>set @gameId = LAST_INSERT_ID();</xsl:text>

		<xsl:for-each select="html:table/html:tr[position()=last()]">
			<xsl:if test="html:td[position()=1] = 'Totals'">
				<xsl:text>insert into Stats(gameId,team,Minutes,FGM,FGA,`3FG`,`3FGA`,FT,FTA,PTS,OffReb,DefReb,TotReb,AST,`TO`,ST,BLKS,Fouls) values(</xsl:text>
					<xsl:text>@gameId,'</xsl:text>
					<xsl:call-template name="double-single-quotes">
						<xsl:with-param name="text" select="normalize-space(../html:tr[position()=1]/html:td[position()=1])"/>
					</xsl:call-template>
					<xsl:text>',</xsl:text>
					<xsl:call-template name="min-sec-to-just-min">
						<xsl:with-param name="text" select="html:td[position()=3]"/>
					</xsl:call-template>
					<xsl:for-each select="html:td[position()&gt;3]">
						<xsl:text>,</xsl:text>
						<xsl:call-template name="numeric-stats-value">
							<xsl:with-param name="text" select="translate(.,'*/','')"/>
						</xsl:call-template>
					</xsl:for-each>
				<xsl:text>);</xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:for-each>
</xsl:template>

<xsl:template match="*">
	<!-- Override the default rule, which would include the rest of the file as text. -->
</xsl:template>

<xsl:template name="double-single-quotes">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, $sq)">
			<xsl:value-of select="substring-before($text, $sq)"/>
			<xsl:value-of select="$dsq" />
			<xsl:call-template name="double-single-quotes">
				<xsl:with-param name="text" select="substring-after($text, $sq)"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="min-sec-to-just-min">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, ':')">
			<xsl:value-of select="substring-before($text,':')"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="numeric-stats-value">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="$text=''">
			<xsl:text>0/*blank*/</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
