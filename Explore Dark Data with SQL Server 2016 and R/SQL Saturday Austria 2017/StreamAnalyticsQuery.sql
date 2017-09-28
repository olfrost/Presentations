WITH CTE AS
(
    SELECT 
        GetArrayElement([word], 0) as Word,
        GetArrayElement([Freq], 0) as Freq
    FROM 
        [SQL2016R]
)
SELECT    
    System.TimeStamp AS WindowEnd,
    Word,
    SUM(CAST(Freq as bigint)) as Freq
FROM
    CTE
GROUP BY
    Word, 
    TumblingWindow(Duration(minute, 1), Offset(millisecond, -1));
