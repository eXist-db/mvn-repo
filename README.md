mvn-repo
========

Maven repository

## Example

add to pom file:

```
  <dependencies>
    <!-- eXistDB Library -->
    <dependency>
      <groupId>org.exist-db</groupId>
      <artifactId>existdb-core</artifactId>
      <version>2.0</version>
    </dependency>
  </dependencies>
  
  <repositories>
    <repository>
      <id>eXistDB</id>
      <url>https://raw.github.com/eXist-db/mvn-repo/master/</url>
    </repository>
  </repositories>
```
