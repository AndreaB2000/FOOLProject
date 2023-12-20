# Tutorial per scimmie su come completare il compilatore per FOOL
## Introduzione
Verranno modificati i seguenti file:
 - ./AST.java
 - ./ASTGenerationSTVisitor.java
 - ./CodeGenerationSTVisitor.java
 - ./PrintEASTVisitor.java
 - ./TypeCheckEASTVisitor.java
 - ./SymbolTableASTVisitor.java
 - ./lib/BaseASTVisitor.java
 - ./compiler/FOOL.g4

Sarà inoltre necessario ri-generare il parser con ANTLR (ho trovato un conflitto di versioni, usando la 4.13.1 invece della 4.12.0 si sistema tutto)

## Procedimento
Arriviamo quindi al procedimento vero e proprio, elencando i singoli passaggi e fornendo degli esempi. Da questo momento il cervello può essere comodamente riposto sulla scrivania, su un ripiano, o in un cassetto, a seconda dell'organizzazione della stanza in cui ci si trova.

**Modifica dei file .g4**: aggiungere l'operatore richiesto inserendo una riga come mostrato nel seguente listato:

```
exp     : exp TIMES exp #times
        | exp PLUS  exp #plus
        | exp EQ  exp   #eq
        | exp LESSEQ exp #lesseq    // Added

        [...]
	    
        | ID LPAR (exp (COMMA exp)* )? RPAR #call
        ; 
```

Aggiungere anche il lessema corrispondente:

```
[...]

SEMIC 	: ';' ;
COLON   : ':' ; 
COMMA	: ',' ;
EQ	    : '==' ;
LESSEQ  : '<=';     // Added
ASS	    : '=' ;
TRUE	: 'true' ;
FALSE	: 'false' ;

[...]
```

Si modifichino ora i file citati nell'introduzione seguendo questi esempi, inferiti dal codice già scritto:

AST.java:
```
public static class LessEqualNode extends Node {
		final Node left;
		final Node right;
		LessEqualNode(Node l, Node r) {
			this.left = l;
			this.right = r;
		}

		@Override
		public <S, E extends Exception> S accept(BaseASTVisitor<S, E> visitor) throws E {
			return visitor.visitNode(this);
		}
	}
```

ASTGenerationSTVisitor.java:
```
@Override
public Node visitLesseq(LesseqContext c) {
    if (print) printVarAndProdName(c);
    Node n = new LessEqualNode(visit(c.exp(0)), visit(c.exp(1)));
    n.setLine(c.LESSEQ().getSymbol().getLine());
    return n;
}
```

CodeGenerationSTVisitor.java:
```
@Override
public String visitNode(LessEqualNode n) {
    if (print) printNode(n);
    String l1 = freshLabel();
    String l2 = freshLabel();
    
    return nlJoin(
            visit(n.left),
            visit(n.right),
            "bleq "+l1,
            "push 0",
            "b "+l2,
            l1+":",
            "push 1",
            l2+":"
    );
}
```
*questo è l'unico punto in cui forse va scomodato il cervello; in questo caso è bastato aggiungere una "l" e far diventare "beq" un'istruzione "bleq"*

PrintEASTVisitor.java:
```
@Override
public Void visitNode(LessEqualNode n) {
    printNode(n);
    visit(n.left);
    visit(n.right);
    return null;
}
```

TypeCheckEASTVisitor.java:
```
@Override
public TypeNode visitNode(LessEqualNode n) throws TypeException {
    if (print) printNode(n);
    TypeNode l = visit(n.left);
    TypeNode r = visit(n.right);
    if ( !(isSubtype(l, r) || isSubtype(r, l)) )
        throw new TypeException("Incompatible types in less-equal",n.getLine());
    return new BoolTypeNode();
}
```
*qui è stato modificato il testo dell'eccezione*

SymbolTableASTVisitor.java:
```
@Override
public Void visitNode(LessEqualNode n) {
    if (print) printNode(n);
    visit(n.left);
    visit(n.right);
    return null;
}
```

lib/BaseASTVisitor.java:
```
public S visitNode(LessEqualNode n) throws E {throw new UnimplException();}
```

A questo punto, ri-generando il parser con ANTLR, dovrebbe già funzionare tutto.

## Testing
Si può testare la nuova funzionalità modificando il file `test.fool`.

## Quali funzionailtà sviluppare
Le funzionalità da sviluppare sono in tutto: `<=`, `>=`, `||`, `&&`, `/`, '-' e `!`.
