TARGETS= email_catcher
CPYTHONLIB= -L/usr/lib -lpython2.7 -lpthread -ldl  -lutil -lm  -Xlinker -export-dynamic


default: $(TARGETS)

email_catcher: lex.yy.o
	gcc $(CPYTHONLIB) $^ -lfl -o $@

%.o: %.c
	gcc -c $^ -o $@

lex.yy.c: email_catcher.lex
	lex email_catcher.lex

clean:
	rm *~ lex.yy.* $(TARGETS)
