      implicit real*8 (a-h,o-z)
      character*12 fname,filename(20)
      logical filflg
      common /aa/ ia(143610000)
      common /bb/ ib(71800000)
      open (1,file=' ',form='unformatted',status='old')
      read (1) knode,ncoor
      close(1)
      kdgof = 2
      kvar=knode*kdgof
      kcoor=ncoor
      kelem=17950000
      knb1=kdgof*knode*1
      if (knb1/2*2 .lt. knb1) knb1=knb1+1
      kna1=kdgof*knode*2
      kna3=kcoor*knode*2
      kna4=kdgof*knode*2
      kna5=knode*2
      kna6=knode*2
      kna7=kvar*2
      kna2=kvar*2
      kna9=10000*2
      kna8=kelem*2
      knb2=kelem*1
      if (knb2/2*2 .lt. knb2) knb2=knb2+1
      kna0=1
      kna1=kna1+kna0
      kna2=kna2+kna1
      kna3=kna3+kna2
      kna4=kna4+kna3
      kna5=kna5+kna4
      kna6=kna6+kna5
      kna7=kna7+kna6
      kna8=kna8+kna7
      kna9=kna9+kna8
      if (kna9-1.gt.143610000) then
      write(*,*) 'exceed memory of array ia'
      write(*,*) 'memory of ia = 143610000'
      write(*,*) 'memory needed = ',kna9,' in prgram ecgmc'
      stop 55555
      endif
      knb0=1
      knb1=knb1+knb0
      knb2=knb2+knb1
      if (knb2-1.gt.71800000) then
      write(*,*) 'exceed memory of array ib'
      write(*,*) 'memory of ib = 71800000'
      write(*,*) 'memory needed = ',knb2,' in prgram ecgmc'
      stop 55555
      endif
      call ecgmc(knode,kdgof,kvar,kcoor,
     *numtyp,numel,neq,kelem,lr,ia(kna0),ia(kna1),
     *ia(kna2),ia(kna3),ia(kna4),ia(kna5),ia(kna6),
     *ia(kna7),ia(kna8),ib(knb0),ib(knb1),
     *filename)
      end
      subroutine ecgmc(knode,kdgof,kvar,kcoor,
     *numtyp,numel,neq,kelem,lr,u,
     *f,coor,eu,eun,evn,emass,
     *sml,emate,nodvar,node,
     *filename)
      implicit real*8 (a-h,o-z)
      character*12 filename(20)
        dimension nodvar(kdgof,knode),u(kdgof,knode),coor(kcoor,knode),
     *eu(kdgof,knode),eun(knode),evn(knode),emass(kvar),
     & f(kvar),emate(10000),sml(kelem),node(kelem)
       logical filflg
 
c ...............................................................c
c         compute the solution by least square method            c
c ...............................................................c
c ..... kdgof number of d.o.f
c ..... knode number of nodes
c ..... nodvar denote the equation number corresponding the d.o.f
c ..... u initial value
c ..... coor coordinates
c ..... f right hand side term of the equation
c ..... sml store the element stif,mass,damp matrix and load
c ..... node element nodal connection
c ..... emate element material
c .................................................................
6     format (1x,26i3)
7     format (1x,6e12.3)
1001  format(1x,9i7)
 
      inquire(file='time',exist=filflg)
      if (filflg) then
      open(26,file='time',form='unformatted',status='old')
      read(26) tmax,dt,time,it
      close(26)
      write(*,*) 'tmax,time,dt,it =',tmax,time,dt,it
      endif
 
c.......compute nodvar
c      do 50 j=1,knode
c      do 30 i=1,kdgof
c      if (nodvar(1,j).lt.-1) then
c      nodvar(i,j) = nodvar(1,j)
c      else
c      nodvar(i,j) = 1
c      endif
c30    continue
c50    continue
 
      neq = 0
      do 100 j=1,knode
      do 100 i=1,kdgof
c      if (nodvar(i,j).ge.-1) then
      neq = neq+1
      nodvar(i,j) = neq
c      else
c      n = -nodvar(i,j)-1
c      nodvar(i,j) = nodvar(i,n)
c      endif
      u(i,j) = 0.d0
100   continue
c      write(*,*) 'kdgof =',kdgof,' knode =',knode
c      write (*,*) 'nodvar ='
c      write (*,6) ((nodvar(i,j),i=1,kdgof),j=1,knode)
 
c.......open coor file
      open (1,file=' ',form='unformatted',status='old')
      read (1) numnod,ncoor,((coor(i,j),i=1,ncoor),j=1,numnod)
      close(1)
c      write(*,*) 'numnod,ncoor=',numnod,ncoor
 
      numtyp = 2
      if (it.eq.0) then
      open(11,file='ugoal',form='unformatted',status='old')
      else
      open(11,file='ugoal',form='unformatted',status='old')
      endif
      read(11) (eun(i),i=1,knode),
     &  (evn(i),i=1,knode)

      do 110 i=1,neq
      emass(i) = 0.d0
110   continue
      numel=0
c.......open elem0 file
      open (3,file=' ',form='unformatted',status='old')
c.......numtyp number of element types
      do 2000 ityp=1,numtyp
c.......read nodal connection points and material no.
c.......num .... number of elements
c.......nnode .... number of nodes for each element
      read (3) num,nnode,
     *           ((node((i-1)*nnode+j),j=1,nnode),i=1,num)
c      write(*,*) 'num =',num,' nnode =',nnode
c      write(*,*) 'node ='
c      write(*,6) ((node((i-1)*nnode+j),j=1,nnode),i=1,num)
      nne = nnode
      nne = nne-1
      k=0
      do 116 j=1,nne
      jnod = node(j)
      if (jnod.le.0) goto 116
      do 115 l=1,kdgof
      if (nodvar(l,jnod).ne.0) k=k+1
115   continue
116   continue
c      write(*,*) 'k =',k
      kk=k*k
      k0=1
      k1=k0+k*k
      k2=k1+k
      k3=k2+k
      k4=k3+k*k
      k5=k4+k*k
      k6=k5+k
      k7=k6+k
      call etsub(knode,kdgof,it,kcoor,kelem,k,kk,nnode,nne,
     *numel,ityp,ncoor,num,time,dt,nodvar,coor,node,emate,
     &sml(k0),sml(k1),sml(k2),sml(k3),sml(k4),sml(k5),sml(k6),
     &eun,evn,eu,emass,
     *u)
      numel = numel + num
2000  continue
 

      close(3)
      close(11)

      do 123 i=1,knode
      en=dsqrt(u(1,i)**2+u(2,i)**2)
      if(en.lt.1.d-10) goto 123
      do j=1,kdgof
      u(j,i)=u(j,i)/en
      enddo
123   continue

      open(10,file=' ',form='unformatted',status='unknown')
      write(10)  ((u(j,i),i=1,knode),j=1,kdgof)
      close(10)
	  
      end
 
 
      subroutine etsub(knode,kdgof,it,kcoor,kelem,k,kk,nnode,nne,
     & numel,ityp,ncoor,num,time,dt,nodvar,coor,node,emate,
     *es,em,ef,estifn,estifv,emassn,emassv,
     *eun,evn,eu,emass,
     & u)
      implicit real*8 (a-h,o-z)
      dimension nodvar(kdgof,knode),coor(kcoor,knode),node(kelem),
     & u(kdgof,knode),emate(300),
     *es(k,k),em(k),ef(k),eun(knode),
     *evn(knode),eu(kdgof,knode),estifn(k,k),estifv(kk),
     *emassn(k),emassv(k),emass(1),
     & r(500),prmt(500),coef(500),lm(500)
17      format (1x,15i5)
18      format (1x,8e9.2)
 
	read (3) mmate,nmate,((emate((i-1)*nmate+j),j=1,nmate),
     *	i=1,mmate)
	write(*,*) 'mmate =',mmate,' nmate =',nmate
	write (*,*) 'emate ='
	write (*,18) ((emate((i-1)*nmate+j),j=1,nmate),
     *	i=1,mmate)
        do 1000 ne=1,num
	nr=0
	do 130 j=1,nne
	jnod = node((ne-1)*nnode+j)
        if (jnod.lt.0) jnod = -jnod
        prmt(nmate+7+j) = jnod
      coef(j+0*nne)=eun(jnod)
      coef(j+1*nne)=evn(jnod)
	do 120 i=1,ncoor
	nr=nr+1
120	r(nr) = coor(i,jnod)
130	continue
	imate = node(nnode*ne)
	do 140 j=1,nmate
140	prmt(j) = emate((imate-1)*nmate+j)
	prmt(nmate+1)=time
	prmt(nmate+2)=dt
        prmt(nmate+3)=imate
        prmt(nmate+4)=ne
        prmt(nmate+5)=num
        prmt(nmate+6)=it
        prmt(nmate+7)=nmate
        prmt(nmate+8)=itime
        prmt(nmate+9)=ityp
 
      goto (1,2), ityp
1     call ceq9g3(r,coef,prmt,es,em,ec,ef,ne)
      goto 3
2     call cgl3g3(r,coef,prmt,es,em,ec,ef,ne)
      goto 3
3     continue
 
c       write(*,*) 'es em ef ='
c       do 555 i=1,k
c555    write(*,18) (es(i,j),j=1,k)
c       write(*,18) (em(i),i=1,k)
c       write(*,18) (ef(i),i=1,k)
 
      do 201 i=1,k
      do 201 j=1,k
      estifn(i,j)=0.0
201   continue
      do 202 i=1,k
      estifn(i,i)=estifn(i,i)
      do 202 j=1,k
      estifn(i,j)=estifn(i,j)+es(i,j)
202   continue
      do 203 i=1,k
      emassn(i)=0.0
203   continue
      do 204 i=1,k
      emassn(i)=emassn(i)+em(i)
204   continue
 
	l=0
	m=0
	i=0
	do 700 inod=1,nne
	nodi=node((ne-1)*nnode+inod)
	do 600 idgf=1,kdgof
	inv=nodvar(idgf,nodi)
	if (inv.eq.0) goto 600
	i=i+1
	if (inv.lt.0) goto 305
	l=l+1
	lm(l)=inv
	u(idgf,nodi)=u(idgf,nodi)
     *+ef(i)
      emassv(l)=emassn(i)
305     j=0
	do 500 jnod=1,nne
	nodj=node((ne-1)*nnode+jnod)
	do 400 jdgf=1,kdgof
	jnv=nodvar(jdgf,nodj)
	if (jnv.eq.0) goto 400
	j=j+1
 
	if (jnv.lt.0) goto 400
	if (inv.lt.0) goto 310
	m=m+1
      estifv(m)=estifn(i,j)
310     continue
 
 
	if (inv.lt.0)
     *  u(jdgf,nodj)=u(jdgf,nodj)-estifn(i,j)*u(idgf,nodi)
400     continue
500     continue
600     continue
700     continue
c       write (*,*) 'u ='
c       write (*,18) ((u(j,i),j=1,kdgof),i=1,knode)
 
	lrd=m
	ner=numel+ne
	do 800 i=1,l
	j=lm(i)
      emass(j) = emass(j) + emassv(i)
800     continue
 
1000    continue
 
	end
