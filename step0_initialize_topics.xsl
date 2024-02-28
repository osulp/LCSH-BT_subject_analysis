<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
            
    <xsl:template match="/">
        
        <xsl:result-document href="0-4_topic_list.xml">

            <topic_list>
                <meta>
                    <xsl:variable name="lcsh_count" select="count(//subject)"/>
                    <xsl:variable name="unique_root_count" select="count(distinct-values(//root_subject))"/>
                    <total_original_lcsh>
                        <xsl:value-of select="$lcsh_count"/>
                    </total_original_lcsh>
                    <unique_root_subjects>
                        <xsl:value-of select="$unique_root_count"/>
                    </unique_root_subjects>
                </meta>

                <xsl:for-each-group select="/subject_list/subject" group-by="root_subject">
                    <xsl:sort order="descending" select="count(current-group())"/>
                    <xsl:variable name="label" select="current-grouping-key()"/>
                    
                    <topic>
                        <label>
                            <xsl:value-of select="$label"/>
                        </label>
                        <occurrences self_or_subdiv="{count(current-group())}"/>
                    </topic>
                </xsl:for-each-group>

            </topic_list>
        </xsl:result-document>

    </xsl:template>

</xsl:stylesheet>