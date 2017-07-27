# Platform.xsd
```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema elementFormDefault="qualified" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<xsd:element name="MESSAGE_GROUP">
		<xsd:complexType>
			<xsd:sequence>
				<xsd:element ref="MESSAGE" maxOccurs="unbounded"/>
			</xsd:sequence>
		</xsd:complexType>
	</xsd:element>
	<xsd:element name="MESSAGE">
		<xsd:complexType>
			<xsd:sequence>
				<xsd:element ref="MESSAGE_CONTENT"/>
				<xsd:element ref="DEST_GROUP"/>
			</xsd:sequence>
		</xsd:complexType>
	</xsd:element>
	<xsd:element name="DEST_GROUP">
		<xsd:complexType>
			<xsd:sequence>
				<xsd:element ref="DEST" maxOccurs="unbounded"/>
			</xsd:sequence>
		</xsd:complexType>
	</xsd:element>
	<xsd:element name="DEST">
		<xsd:complexType>
			<xsd:sequence>
				<xsd:element ref="DEST_NAME"/>
				<xsd:element ref="DEST_FORENAME"/>
				<xsd:element ref="TERMINAL_ADDR"/>
			</xsd:sequence>
		</xsd:complexType>
	</xsd:element>
	<xsd:element name="TERMINAL_ADDR" type="xsd:string"/>
	<xsd:element name="DEST_FORENAME" type="xsd:string"/>
	<xsd:element name="DEST_NAME" type="xsd:string"/>
	<xsd:element name="MESSAGE_CONTENT" type="xsd:string"/>
</xsd:schema>
```
