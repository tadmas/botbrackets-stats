<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:html="http://www.w3.org/1999/xhtml">

<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
<xsl:strip-space elements="*"/>

<xsl:param name="GAMENO"/>
<xsl:variable name="sq">'</xsl:variable>
<xsl:variable name="dsq">''</xsl:variable>

<xsl:template match="/">
	<xsl:apply-templates select="/" mode="game-summary"/>
	<xsl:apply-templates select="/" mode="team-stats">
		<xsl:with-param name="colno" select="2"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="/" mode="team-stats">
		<xsl:with-param name="colno" select="3"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template match="/" mode="game-summary">
	<xsl:for-each select="html:html/html:body//html:div[@class='table-responsive']/html:table[position() = 1]/html:tr[position() = 1]//html:table">
		<xsl:text>insert into Games(ncaaGameNo,teamA,teamAScore,teamB,teamBScore,gameDate,location) values (</xsl:text>
			<xsl:value-of select="$GAMENO"/>
			<xsl:for-each select=".//html:tr[(position() = 2) or (position() = 3)]">
				<xsl:text>,'</xsl:text>
				<xsl:call-template name="parse-team-name">
					<xsl:with-param name="text" select="normalize-space(./html:td[position() = 1])"/>
				</xsl:call-template>
				<xsl:text>',</xsl:text>
				<xsl:value-of select="./html:td[position()=last()]"/>
			</xsl:for-each>

			<xsl:text>,'</xsl:text>
			<xsl:for-each select=".//html:tr[position() = 4]">
				<xsl:value-of select=".//html:td[position() = 1]"/>
			</xsl:for-each>

			<xsl:text>','</xsl:text>
			<xsl:for-each select=".//html:tr[position() = 5]">
				<xsl:call-template name="double-single-quotes">
					<xsl:with-param name="text" select="translate(.//html:td[position()=1],'\','')"/>
				</xsl:call-template>
			</xsl:for-each>

			<xsl:text>'</xsl:text>
		<xsl:text>);</xsl:text>

		<xsl:text>set @gameId = LAST_INSERT_ID();</xsl:text>
	</xsl:for-each>
</xsl:template>

<xsl:template match="/" mode="team-stats">
	<xsl:param name="colno"/>
	<xsl:for-each select="//html:table[@id = 'rankings_table']">
		<xsl:text>insert into Stats(gameId,team,FGM,FGA,`3FG`,`3FGA`,FT,FTA,PTS,OffReb,DefReb,TotReb,AST,`TO`,ST,BLKS,Fouls) values (</xsl:text>
		<xsl:text>@gameId,'</xsl:text>
		<xsl:call-template name="parse-team-name">
			<xsl:with-param name="text" select="normalize-space(.//html:tr[position()=1]/html:th[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>',</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='FGM')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='FGA')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='3FG')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='3FGA')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='FT')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='FTA')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='PTS')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='ORebs')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='DRebs')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='Tot Reb')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='AST')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='TO')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='STL')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='BLK')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>,</xsl:text>
		<xsl:call-template name="numeric-stats-value">
			<xsl:with-param name="text" select="normalize-space(.//html:tr/html:td[(position()=1) and (.='Fouls')]/..//html:td[position()=$colno])"/>
		</xsl:call-template>
		<xsl:text>);</xsl:text>
	</xsl:for-each>
</xsl:template>

<xsl:template match="*">
	<!-- Override the default rule, which would include the rest of the file as text. -->
</xsl:template>

<xsl:template match="*" mode="game-summary">
	<!-- Override the default rule, which would include the rest of the file as text. -->
</xsl:template>

<xsl:template match="*" mode="team-stats">
	<!-- Override the default rule, which would include the rest of the file as text. -->
</xsl:template>

<xsl:template name="parse-team-name">
	<xsl:param name="text"/>
	<xsl:variable name="italicsremoved">
		<xsl:call-template name="remove-italics">
			<xsl:with-param name="text" select="$text"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="recordremoved">
		<xsl:call-template name="remove-record">
			<xsl:with-param name="text" select="$italicsremoved"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:call-template name="double-single-quotes">
		<xsl:with-param name="text" select="normalize-space($recordremoved)"/>
	</xsl:call-template>
</xsl:template>

<xsl:template name="remove-record">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="translate($text, '(-0123456789) ', '') = ''"/>
		<xsl:when test="contains($text, ' ')">
			<xsl:choose>
				<xsl:when test="translate(substring-before($text, ' '), '#0123456789', '') = ''"/>
				<xsl:otherwise>
					<xsl:value-of select="substring-before($text, ' ')"/>
					<xsl:text> </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="remove-record">
				<xsl:with-param name="text" select="substring-after($text, ' ')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="remove-italics">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '&lt;i&gt;')">
			<xsl:value-of select="substring-before($text, '&lt;i&gt;')" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="$text"/>
		</xsl:otherwise>
	</xsl:choose>
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
