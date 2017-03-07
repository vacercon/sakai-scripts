1)Crear tablas
Lanzar creacion_tablas.txt

2)Crear paquetes
Lanzar creacion_paquetes.txt

3)Calcular referencias (le puede costar m�s de una hora dependiendo del tama�o y rendimiento)
Lanzar paquete
BEGIN 
  SAK_UTL_REFERENCIAS_PCK.PROCESAR_TODO;
  COMMIT; 
END;

4)Comprobar las referencias creadas
select * from sak_utl_referencias


5)Borrado de un site. Ejemplo.
Comprobando que es de un curso antiguo, no tiene referencias, profesores activos, no publicado, etc
Comprobar 10 veces, borrar una.

begin
  for reg in (
  select ss.site_id
    from sakai_site ss,sakai_site_property ssp
   where ss.site_id='site_elegido'
         and ss.type in ('xxx')
         and ssp.site_id=ss.site_id and ssp.name='term'
         and dbms_lob.substr(ssp.value,4) in ('2006','2007')
         and not exists (select 'x' from sak_utl_referencias u where site_destino=ss.site_id
             and (exists (select 'x' from sakai_site where site_id=u.site_origen)
                  or
                  exists (select 'x' from sakai_site where site_id='~'||u.site_origen)
                 )
         )
         and published=0
         and not exists (
              select 'x'
                from sakai_realm_rl_gr srlg,sakai_realm sr,sakai_realm_role srr
               where sr.realm_key=srlg.realm_key
                 and sr.realm_id='/site/'||ss.site_id
                 and srr.role_key=srlg.role_key
                 and role_name in ('profesor','admin','ayudante','coordinador')
                 and srlg.active='1'))
  loop
  delete_site_content.borrar_site(reg.site_id);
  end loop;
end;

6)Borrado de sistema de ficheros
Volcar el resultado de esta select en un fichero de SO linux

select file_path from BORRAR_SITES_RESOURCES_FS where borrado='N'
and site_id like '%2006'

Ponerlo en la carpeta correspondiente y lanzarlo

Marcar los borrados
update BORRAR_SITES_RESOURCES_FS
   set borrado='S' 
 where borrado='N'
   and site_id like '%2006'


/////////////
A tener en cuenta

-La UPV tiene todav�a campos LONG, puede que esto falle
-La deshabilitaci�n de las constraints se hace por nombre.
Como cada instalaci�n puede tener diferentes nombres de constraint, habr�a que adaptar el nombre.
-Los sites que son de usuario no empiezan por '~' en la tabla sak_utl_referencias