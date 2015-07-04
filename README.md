Maven Repository for compiled eXist artifacts
=============================================

This repository holds the POMs for eXist compiled artifacts. In addition it holds any dependencies which cannot themselves be retrieved from Maven Central.

## Example

To use the core of eXist in your Maven project, add the dollowing to the `dependencies` section of your Maven `pom.xml` file:

```xml
    <dependency>
      <groupId>org.exist-db</groupId>
      <artifactId>exist-core</artifactId>
      <version>3.0.RC1</version>
    </dependency>
```

You will also need to add this repository to (or create) the `repositories` section of your Maven `pom.xml` file:

```xml
    <repository>
      <id>exist</id>
      <url>https://raw.github.com/eXist-db/mvn-repo/master/</url>
    </repository>
```

These artifacts can also be used from Ivy, SBT or Gradle build systems.
