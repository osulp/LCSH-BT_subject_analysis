<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ead="urn:isbn:1-931666-22-9"
    xpath-default-namespace="urn:isbn:1-931666-22-9"
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <!-- ATTENTION USER: Specify the name of the directory containing the EAD XML files -->
    <xsl:variable name="folder_name" select="'ead_xml'"/>
    <!-- ATTENTION USER: Specify the relative path to the directory containing the EAD XML files -->
    <xsl:variable name="folder_path" select="'../source_xml/'"/>
    <!-- Construct the path to the directory containing the EAD XML files; specify XML files only -->
    <xsl:variable name="ead_files" select="collection(concat($folder_path,$folder_name,'/?select=*.xml'))"/>
    
    <xsl:template match="/">
        
        <!-- Send output to a document -->
        <xsl:result-document href="0_all_ead_lcsh.xml">
            <subject_list>

            <!-- Apply the rest of the template to each EAD XML file in the specified directory -->
            <xsl:for-each select="$ead_files">
                
                <!-- Derive the Archon ID from the source document filename -->
                <xsl:variable name="archon_id"
                    select="substring-after(substring-before(base-uri(), '.xml'), concat($folder_name, '/'))"/>
                
                <!-- Create an entry for each subject found -->
                <xsl:for-each select="/ead/archdesc/controlaccess/controlaccess/subject[@source='lcsh']">
                        <subject>
                            <archon_id>
                                <xsl:value-of select="$archon_id"/>
                            </archon_id>
                            <full_subject>
                                <xsl:value-of select="."/>
                            </full_subject>
                            <root_subject>
                                <xsl:choose>
                                    <xsl:when test="contains(., '--')">
                                        <xsl:value-of select="substring-before(., '--')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="replace(., '\.', '')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </root_subject>
                            <type>
                                <xsl:text>LCSH</xsl:text>
                            </type>
                        </subject>
                </xsl:for-each>
                
            </xsl:for-each>
            
            </subject_list>
            
        </xsl:result-document>

    </xsl:template>

</xsl:stylesheet>