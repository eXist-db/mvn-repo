# Maven Repository for compiled eXist artifacts
[![Build Status](https://travis-ci.org/eXist-db/mvn-repo.png?branch=master)](https://travis-ci.org/eXist-db/mvn-repo)

This repository holds the POMs for eXist compiled artifacts. In addition it holds any dependencies which cannot themselves be retrieved from Maven Central.

Unfortunately this does not work well as a source for Nexus proxy repositiories. As an alternative [Evolved Binary](http://www.evolvedbinary.com) mainatin a public Nexus repository of eXist-db artifacts here: http://repo.evolvedbinary.com/repository/exist-db/ (and snapshots here: http://repo.evolvedbinary.com/repository/exist-db-snapshots/)

## Example

To use the core of eXist in your Maven project, add the dollowing to the `dependencies` section of your Maven `pom.xml` file:

```xml
    <dependency>
      <groupId>org.exist-db</groupId>
      <artifactId>exist-core</artifactId>
      <version>5.0.0-RC3</version>
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


Caveats
=======

These artifacts are manually constructed from the output of the eXist-db Ant build process on a best effort basis.

**eXist 3.0 Maven Artifacts** - these are built from the Git commit id 9911af8 as the tag for eXist 3.0 is not correct!


Scripts for producing Maven Artifacts from eXist-db
===================================================

1. Build the JARs and generate checksum files for them

```bash
./update.sh
```

or if you want to produce a **SNAPSHOT** version:

```bash
./update.sh --shapshot
```

or if you want to use a specific version name:

```bash
./update.sh --tag 5.0.0-RC3
```

2. Migrate the last version of the POMs

```bash
./migrate-pom-versions.sh 5.0.0-RC2 5.0.0-RC3
```

3. Make any changes to the POM files that you need to make (e.g. updating dependency versions)


4. Create checksum files for the POMs
```bash
./create-pom-checksums.sh
```

5. Validate the checksums
```bash
./validate-checksums.sh
```

6. If (5) passes then upload the Artifacts to the remote repo (optional):
```bash
./upload.sh 5.0.0-RC3
```

or if you want to install locally (perhaps because you built a snapshot):

```bash
./upload.sh --local 20170104-SNAPSHOT
```

7. Upload the artifacts to GitHub

    1. Modify the README.md replacing the version numbers with the latest

    2. Add, commit and push the files to GitHub:

    ```bash
    git add README.md
    git add **5.0.0-RC3**
    git commit
    git push
    ```

